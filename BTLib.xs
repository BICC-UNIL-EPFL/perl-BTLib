/* -*- C -*- */
#ifdef __cplusplus
extern "C" {
#endif
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#ifndef __GNUC__
#include "alloca.h"
#endif
#ifdef __cplusplus
}
#endif
#define AUTODIN_IIREV	0xEDB88320
#define POLY64REV	0xd800000000000000ULL

MODULE = BTLib		PACKAGE = BTLib
PROTOTYPES: ENABLE

int
SPcrc32(s)
  char *s
  CODE:
  static unsigned CRCTable[256];
  static int init = 0;
  unsigned crc = 0xFFFFFFFF;

  if (!init) {
    int i;
    init = 1;
    for (i = 0; i <= 255; i++) {
      int j;
      unsigned part = i;
      for (j = 0; j < 8; j++) {
        if (part & 1)
          part = (part >> 1) ^ AUTODIN_IIREV;
        else
          part >>= 1;
      }
      CRCTable[i] = part;
    }
  }
  while (*s) {
    unsigned temp1 = crc >> 8;
    unsigned temp2 = CRCTable[(crc ^ (unsigned) *s) & 0xff];
    crc = temp1 ^ temp2;
    s += 1;
  }
  RETVAL = crc;
  OUTPUT:
  RETVAL

char *
SPcrc64(s)
  char *s
  CODE:
  static unsigned long long CRCTable[256];
  unsigned long long crc = 0;
  static int init = 0;
  char res[17];

  if (!init) {
    int i;
    init = 1;
    for (i = 0; i <= 255; i++) {
      int j;
      unsigned long long part = i;
      for (j = 0; j < 8; j++) {
        if (part & 1)
          part = (part >> 1) ^ POLY64REV;
        else
          part >>= 1;
      }
      CRCTable[i] = part;
    }
  }
  while (*s) {
    unsigned long long temp1
      = crc >> 8;
    unsigned long long temp2
      = CRCTable[(crc ^ (unsigned long long) *s) & 0xff];
    crc = temp1 ^ temp2;
    s += 1;
  }
  sprintf(res, "%016llX", crc);
  RETVAL = res;
  OUTPUT:
  RETVAL

char *
na2aa(s)
  char *s
  CODE:
  static char *CABC = "KNKNTTTTRSRSIIMI"  /* AAA AAC ... ATT */
		      "QHQHPPPPRRRRLLLL"  /* CAA CAC ... CTT */
		      "EDEDAAAAGGGGVVVV"  /* GAA GAC ... GTT */
		      "OYOYSSSSOCWCLFLF"; /* TAA TAC ... TTT */
  static char *CNBC = "XTXXXPRLXAGVXSXX"; /* AAN ACN ... TTN */
#ifdef __GNUC__
  char res[strlen(s)/3+2];
#else
  char *res = alloca(sizeof(char) * (strlen(s)/3+2));
#endif
  char *cur = res;

  while (*s) {
    int idx = 0;
    /* Check first nt.  */
    switch (*s) {
    case 'A':
    case 'a':
      break;
    case 'C':
    case 'c':
      idx = 1;
      break;
    case 'G':
    case 'g':
      idx = 2;
      break;
    case 'T':
    case 't':
      idx = 3;
      break;
    default:
      idx = -1;
    }
    s += 1;
    if (*s == 0) {
      *cur++ = 'X';
      break;
    }
    if (idx == -1) {
      *cur++ = 'X';
      s += 1;
      if (*s == 0)
	break;
      s += 1;
      continue;
    }
    idx <<= 2;
    /* Check second nt.  */
    switch (*s) {
    case 'A':
    case 'a':
      break;
    case 'C':
    case 'c':
      idx += 1;
      break;
    case 'G':
    case 'g':
      idx += 2;
      break;
    case 'T':
    case 't':
      idx += 3;
      break;
    default:
      idx = -1;
    }
    s += 1;
    if (*s == 0) {
      if (idx == -1)
	*cur++ = 'X';
      else
	*cur++ = CNBC[idx];
      break;
    }
    if (idx == -1) {
      *cur++ = 'X';
      s += 1;
      continue;
    }
    idx <<= 2;
    /* Check third nt.  */
    switch (*s) {
    case 'A':
    case 'a':
      break;
    case 'C':
    case 'c':
      idx += 1;
      break;
    case 'G':
    case 'g':
      idx += 2;
      break;
    case 'T':
    case 't':
      idx += 3;
      break;
    default:
      *cur++ = CNBC[idx >> 2];
      idx = -1;
    }
    if (idx != -1)
      *cur++ = CABC[idx];
    s += 1;
  }
  *cur = 0;
  RETVAL = res;
  OUTPUT:
  RETVAL

#
