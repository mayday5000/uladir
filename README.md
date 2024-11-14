# uladir


FAT12 5 1/4 Diskette file listing POC using Intel 8088 compatible assembly (the first PC). Shows attributes and deleted files.
2003 - Damian Andres Ulanowicz.


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

