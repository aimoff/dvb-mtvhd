#ifndef _ASV5211FW_H_
#define _ASV5211FW_H_

#include <stdint.h>
#include <asm/byteorder.h>

#define ASV5211_FW_MAX_COUNT	4

struct asv5211_fw_block
{
	__le16	offset;
	__le16	length;
};

struct asv5211_fw_header
{
	char		name[8];	/* 00: "ASV5211" */
	__le16		version;	/* 08: Firmware version ?? */
	__le16		sum;		/* 0A: Checksum */
	uint8_t		header_size;	/* 0C: Header size */
	uint8_t		header_sum;	/* 0D: Checksum for header */
	uint8_t		reserved;	/* 0E */
	uint8_t		count;		/* 0F: Number of FW block */
};

#endif	/* _ASV5211FW_H_ */
