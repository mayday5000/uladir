# uladir
;-----------------------------------------------------------------------------

;              Creado por Damian Andres Ulanowicz (2003).

;-----------------------------------------------------------------------------

FAT12 5 1/4 Diskette file listing. Shows attributes and hidden files.

Output format:

Bar          DB   'Attrib Name     Ext   Id          Size Clust   Date     Time   Accessed Checksum'

;                  rhsadv 12345678.123 Del LFN 1123123456 65535 18-10-79 12.12.12 18-10-79

id_lfn       DB 'LFN    '
id_erased    DB 'Erased '
id_del_lfn   DB 'Del LFN'
id_volume    DB 'Volume '
id_directory DB 'Direct.'
id_archive   DB 'Archive'

\

