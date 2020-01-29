# uladir
;-----------------------------------------------------------------------------

;              Creado por Damian Andres Ulanowicz (2003).

;-----------------------------------------------------------------------------

FAT12 5 1/4 Diskette file listing. Shows attributes and deleted files.

Output format:
--------------

Attrib Name     Ext   Id          Size Clust   Date     Time   Accessed Checksum


Attributes:
-----------

id_lfn       DB 'LFN    '

id_erased    DB 'Erased '

id_del_lfn   DB 'Del LFN'

id_volume    DB 'Volume '

id_directory DB 'Direct.'

id_archive   DB 'Archive'

\

