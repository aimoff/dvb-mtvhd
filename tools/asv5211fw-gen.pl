#!/usr/bin/perl

my $down = ();
my $final = ();
my $fw_count = 0;
my $fw_version = ();
my @fw_offset = ();
my @fw_length = ();
my $len = 0;

sub usage {
	print(STDERR
		"ASV5211 firmware generator\n",
		"  Usage: $0 [input_log_file [output_c_source_file]]\n"
	);
}

sub err_msg {
	my($msg) = @_;

	printf(STDERR "%s(%d): %s\n", $ARGV, $., $msg);
}

if ( @ARGV > 2 ) {
	usage();
	exit(1);
}

if ( @ARGV > 1 ) {
	open(STDOUT, '>', $ARGV[$#ARGV]);
	pop(@ARGV);
}

print(
	"#include <stdio.h>\n",
	"#include <stdlib.h>\n",
	"#include <string.h>\n",
	"#include \"asv5211fw.h\"\n",
	"\n"
);

while ( <> ) {
	chomp;
	if ( />>>  URB [0-9]+ going down  >>>/ ) {
		$down = TRUE;
		$len = 0;
		next;
	}
	if ( /<<<  URB [0-9]+ coming back  <<</ ) {
		$down = ();
		last if $final;
		next;
	}
	if ( $down && /TransferBufferLength += ([[:xdigit:]]{8})$/ ) {
		my $xlen = hex($1);
		printf("static uint8_t fw_data_%d[0x%x] = {\n", $fw_count, $xlen);
		$fw_length[$fw_count] = $xlen;
		next;
	}
	if ( $down && /^    ([[:xdigit:]]{8}): ([ [:xdigit:]]+)$/ ) {
		my $offset = hex($1);
		my @data = split(/ /, $2);
		if ( $len != $offset ) {
			err_msg("byte offset mismatch");
			exit(1);
		}
		$len += @data;
		printf("/* %04x */\t", $offset);
		for my $d (@data) {
			printf("0x%02x,", hex($d));
		}
		print("\n");
		next;
	}
	if ( $down && /UrbLink += [[:xdigit:]]{8}$/ ) {
		if ( $len != $fw_length[$fw_count] ) {
			err_msg("data length mismatch");
			exit(1);
		}
		print("};\n\n");
		next;
	}
	if ( /Request += ([[:xdigit:]]{8})$/ ) {
		if ( !$down ) {
			err_msg("unexpected sequence");
			exit(1);
		}
		my $req = hex($1);
		if ( $req == 0xac ) {
			$final = TRUE;
		}
		elsif ( $req != 0xab ) {
			err_msg("unexpected request code");
			exit(1);
		}
		next;
	}
	if ( /Value += ([[:xdigit:]]{8})$/ ) {
		if ( !$down ) {
			err_msg("unexpected sequence");
			exit(1);
		}
		$fw_offset[$fw_count] = hex($1);
		next;
	}
	if ( /Index += ([[:xdigit:]]{8})$/ ) {
		if ( !$down ) {
			err_msg("unexpected sequence");
			exit(1);
		}
		my $idx = hex($1);
		if ( !$fw_version ) {
			$fw_version = $idx;
		}
		elsif ( $fw_version != $idx ) {
			err_msg("unexpected index value");
			exit(1);
		}
		$fw_count++;
		next;
	}
}

printf("static uint8_t *fw_data[%d] = {\n\t", $fw_count);
for (my $i = 0; $i < $fw_count; $i++ ) {
	printf("fw_data_%d, ", $i);
}
print(
	"\n};\n",
	"\n"
);

print(
	"int main(int argc, char **argv)\n",
	"{\n",
	"\tint i, j;\n",
	"\tuint16_t sum;\n",
	"\tuint8_t sum_h, *s;\n",
	"\tFILE *fp;\n",
	"\tstruct asv5211_fw_header fw_header;\n",
	"\tstruct asv5211_fw_block fw_block[ASV5211_FW_MAX_COUNT];\n",
	"\n",
	"\tif ( argc != 2 ) {\n",
	"\t\tfprintf(stderr, \"ASV5211 firmware generator for dvb_usb_asv5211\\n\");\n",
	"\t\tfprintf(stderr, \"  Usage: %s output_firmware_file\\n\", argv[0]);\n",
	"\t\texit(EXIT_FAILURE);\n",
	"\t}\n",
	"\n",
	"\tmemset(&fw_header, 0, sizeof(fw_header));\n",
	"\tmemset(fw_block, 0, sizeof(fw_block));\n",
	"\tfw_header.header_size = sizeof(fw_header) + sizeof(fw_block);\n",
	"\tstrcpy(fw_header.name, \"ASV5211\");\n"
);
printf("\tfw_header.version = __cpu_to_le16(0x%x);\n", $fw_version);
printf("\tfw_header.count = %d;\n", $fw_count);
print(
	"\tif ( fw_header.count > ASV5211_FW_MAX_COUNT ) {\n",
	"\t\tfprintf(stderr, \"Too many firmware blocks - %d\\n\", fw_header.count);\n",
	"\t\texit(EXIT_FAILURE);\n",
	"\t}\n"
);
for (my $i = 0; $i < $fw_count; $i++ ) {
	printf("\tfw_block[%d].offset = __cpu_to_le16(0x%04x);\n", $i, $fw_offset[$i]);
	printf("\tfw_block[%d].length = __cpu_to_le16(0x%04x);\n", $i, $fw_length[$i]);
}
print(
	"\n",
	"\tsum = 0;\n",
	"\tfor ( i = 0; i < fw_header.count; i++ ) {\n",
	"\t\tfor ( j = 0; j < __le16_to_cpu(fw_block[i].length); j++ ) {\n",
	"\t\t\tsum += fw_data[i][j];\n",
	"\t\t}\n",
	"\t}\n",
	"\tfw_header.sum = __cpu_to_le16(sum);\n",
	"\n",
	"\tsum_h = 0;\n",
	"\ts = (uint8_t *)&fw_header;\n",
	"\tfor ( i = 0; i < sizeof(fw_header); i++ ) {\n",
	"\t\tsum_h += s[i];\n",
	"\t}\n",
	"\ts = (uint8_t *)fw_block;\n",
	"\tfor ( i = 0; i < sizeof(fw_block); i++ ) {\n",
	"\t\tsum_h += s[i];\n",
	"\t}\n",
	"\tfw_header.header_sum = 0x100 - sum_h;\n",
	"\n",
	"\tfp = fopen(argv[1], \"w\");\n",
	"\tif ( fp == NULL ) {\n",
	"\t\tperror(argv[1]);\n",
	"\t\texit(EXIT_FAILURE);\n",
	"\t}\n",
	"\n",
	"\tif ( fwrite(&fw_header, sizeof(fw_header), 1, fp) != 1 ) {\n",
	"\t\tperror(argv[1]);\n",
	"\t\texit(EXIT_FAILURE);\n",
	"\t}\n",
	"\n",
	"\tif ( fwrite(fw_block, sizeof(fw_block), 1, fp) != 1 ) {\n",
	"\t\tperror(argv[1]);\n",
	"\t\texit(EXIT_FAILURE);\n",
	"\t}\n",
	"\n",
	"\tfor ( i = 0; i < fw_header.count; i++ ) {\n",
	"\t\tif ( fwrite(fw_data[i], __le16_to_cpu(fw_block[i].length), 1, fp) != 1 ) {\n",
	"\t\t\tperror(argv[1]);\n",
	"\t\t\texit(EXIT_FAILURE);\n",
	"\t\t}\n",
	"\t}\n",
	"\n",
	"\tif ( fclose(fp) != 0 ) {\n",
	"\t\t\tperror(argv[1]);\n",
	"\t\t\texit(EXIT_FAILURE);\n",
	"\t}\n",
	"\n",
	"\treturn EXIT_SUCCESS;\n",
	"}\n"
);
