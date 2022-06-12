# UN Archives Database Design notes

## Item = Doc
The metadata for the Moon and Annan archives consists of one record for each fond, sub-fond, series, folder, or item belonging to these collections. The record type is not explicitly provided as a data attribute but inferred from the record identifier.
For example:
```
 archtype │          sid           
══════════╪════════════════════════
 fond     │ AG-069
 subfond  │ AG-069-001
 series   │ S-1092
 folder   │ S-1092-0032-07
 item     │ S-1092-0032-07-00034
```

In aggregate, here is the breakdown of record types:
```
~# select setname, archtype, count(archtype)
postgres-#    from un_archives.docs
postgres-#    group by setname, archtype
postgres-#    order by setname, count(archtype);
 setname │ archtype │ count  
═════════╪══════════╪════════
 annan   │ fond     │      1
 annan   │ subfond  │      1
 annan   │ series   │     14
 annan   │ folder   │  11215
 annan   │ item     │ 105627
 moon    │ fond     │      1
 moon    │ subfond  │      3
 moon    │ series   │     15
 moon    │ folder   │  10542
 moon    │ item     │  86954
(10 rows)
```
It turns out that PDF files are only associated with items:
```
~# select has_doc, archtype, setname, count(*)
postgres-#    from un_archives.docs
postgres-#    group by has_doc, archtype, setname
postgres-#    order by has_doc desc, count(*) desc;
 has_doc │ archtype │ setname │ count  
═════════╪══════════╪═════════╪════════
 t       │ item     │ annan   │ 105589
 t       │ item     │ moon    │  86954
 t       │ folder   │ moon    │      1
 f       │ folder   │ annan   │  11215
 f       │ folder   │ moon    │  10541
 f       │ item     │ annan   │     38
 f       │ series   │ moon    │     15
 f       │ series   │ annan   │     14
 f       │ subfond  │ moon    │      3
 f       │ subfond  │ annan   │      1
 f       │ fond     │ moon    │      1
 f       │ fond     │ annan   │      1
(12 rows)
```
The one folder with a PDF is an outlier; since that PDF is a listing of the items in the folder, we can ignore it.

If we think of the database representation of a FOIArchive collection as a data warehouse, the docs table is the primary fact table. Each row represents a single doc where the columns contain data such as the title, creator, date, and similar attributes.

*For the UN Archives, the item records should form the docs table. That is, one docs row for each item.*
We will store information about the fonds, sub-fonds, series, and folders in our database. But this information
will be viewed by the end users of the FOIArchive as data attributes of the documents (e.g., this document
belongs to series S-1032).

## Classification
The classification data provided in the UN metadata are associated with
both folders and items:
```
~# select setname, archtype, substr(rights, 1, 40) rights, count(*)
postgres-#    from un_archives.docs
postgres-#    group by setname, archtype, substr(rights, 1, 40)
postgres-#    order by setname, archtype, substr(rights, 1, 40) desc;
 setname │ archtype │                  rights                  │ count  
═════════╪══════════╪══════════════════════════════════════════╪════════
 annan   │ folder   │ ¤                                        │   9836
 annan   │ folder   │ Security level: Unclassified             │    389
 annan   │ folder   │ Security level: Strictly confidential    │    857
 annan   │ folder   │ Security level: Confidential             │    133
 annan   │ fond     │ ¤                                        │      1
 annan   │ item     │ ¤                                        │ 104373
 annan   │ item     │ Security level: Unclassified             │   1184
 annan   │ item     │ Security level: Confidential             │     70
 annan   │ series   │ ¤                                        │     14
 annan   │ subfond  │ ¤                                        │      1
 moon    │ folder   │ ¤                                        │      8
 moon    │ folder   │ Security level: Unclassified             │   2441
 moon    │ folder   │ Security level: Strictly confidential    │   5972
 moon    │ folder   │ Security level: No Security Level        │     12
 moon    │ folder   │ Security level: Confidential             │   2109
 moon    │ fond     │ Ban Ki-moon's papers (those under AG-069 │      1
 moon    │ item     │ Security level: Unclassified             │  73284
 moon    │ item     │ Security level: Strictly confidential    │   4132
 moon    │ item     │ Security level: No Security Level        │    861
 moon    │ item     │ Security level: Confidential             │   8677
 moon    │ series   │ ¤                                        │     15
 moon    │ subfond  │ Records under this sub-fonds were screen │      1
 moon    │ subfond  │ Access to archives in this sub-fonds are │      2
(23 rows)
```
Note that all Moon items have a classification value, but over 100K Annan items
do not. As more the 10% of Annan folders have a classification, the situation
may not be so bleak if we apply the folder's classification to its items.

The five classification values provided in the UN metadata:
* strictly confidential
* confidential
* unclassified
* no security level
* no value provided

### Questions:
1. Internal question: we don't have "strictly confidential" in the FOIArchive
   standard list of classifications (e.g., on the search page: Top Secret,
   Secret, Confidential, Limited Official Use, Unclassified). Do we add it,
   map it to Secret or do something else?
1. Question for the UN: what is the difference between unclassified and
   "no security level"?
1. Confirm with the UN: if a folder has a classification and an item in the
   folder does not, the item "inherits" its folder's classification.
1. If any *no value provided* items remain after applying (3), ask the UN: does
   the lack of a value indicate that it is unknown, has 'no security level' or
   something else entirely?

### Classification & Page Count (early look)
```
~# select rights, pg_cnt, count(pg_cnt)
postgres-#    from un_archives.docs
postgres-#    where archtype = 'item' and rights is not null
postgres-#    group by rights, pg_cnt
postgres-#    order by rights desc, pg_cnt;
                rights                 │ pg_cnt │ count
═══════════════════════════════════════╪════════╪═══════
 Security level: Unclassified          │      1 │ 24128
 Security level: Unclassified          │      2 │ 15111
 Security level: Unclassified          │      3 │  8407
 Security level: Unclassified          │      4 │  5604
 Security level: Unclassified          │      5 │  4104
 Security level: Unclassified          │      6 │  3091
 Security level: Unclassified          │      7 │  2288
 Security level: Unclassified          │      8 │  1789
 Security level: Unclassified          │      9 │  1380
 Security level: Unclassified          │     10 │  1049
 Security level: Unclassified          │     11 │   899
 Security level: Unclassified          │     12 │   705
 Security level: Unclassified          │     13 │   587
 Security level: Unclassified          │     14 │   476
 Security level: Unclassified          │     15 │   461
 Security level: Unclassified          │     16 │   353
 Security level: Unclassified          │     17 │   285
 Security level: Unclassified          │     18 │   304
 Security level: Unclassified          │     19 │   279
 Security level: Unclassified          │     20 │   233
 Security level: Unclassified          │     21 │   241
 Security level: Unclassified          │     22 │   214
 Security level: Unclassified          │     23 │   164
 Security level: Unclassified          │     24 │   164
 Security level: Unclassified          │     25 │   127
 Security level: Unclassified          │     26 │   113
 Security level: Unclassified          │     27 │   139
 Security level: Unclassified          │     28 │   106
 Security level: Unclassified          │     29 │    95
 Security level: Unclassified          │     30 │    86
 Security level: Unclassified          │     31 │    91
 Security level: Unclassified          │     32 │    74
 Security level: Unclassified          │     33 │    67
 Security level: Unclassified          │     34 │    64
 Security level: Unclassified          │     35 │    51
 Security level: Unclassified          │     36 │    62
 Security level: Unclassified          │     37 │    51
 Security level: Unclassified          │     38 │    53
 Security level: Unclassified          │     39 │    50
 Security level: Unclassified          │     40 │    45
 Security level: Unclassified          │     41 │    49
 Security level: Unclassified          │     42 │    40
 Security level: Unclassified          │     43 │    37
 Security level: Unclassified          │     44 │    43
 Security level: Unclassified          │     45 │    42
 Security level: Unclassified          │     46 │    24
 Security level: Unclassified          │     47 │    27
 Security level: Unclassified          │     48 │    23
 Security level: Unclassified          │     49 │    20
 Security level: Unclassified          │     50 │    20
 Security level: Unclassified          │     51 │    20
 Security level: Unclassified          │     52 │    20
 Security level: Unclassified          │     53 │    17
 Security level: Unclassified          │     54 │    20
 Security level: Unclassified          │     55 │    18
 Security level: Unclassified          │     56 │    21
 Security level: Unclassified          │     57 │    15
 Security level: Unclassified          │     58 │    13
 Security level: Unclassified          │     59 │    10
 Security level: Unclassified          │     60 │    16
 Security level: Unclassified          │     61 │    16
 Security level: Unclassified          │     62 │     9
 Security level: Unclassified          │     63 │     9
 Security level: Unclassified          │     64 │    18
 Security level: Unclassified          │     65 │    13
 Security level: Unclassified          │     66 │    11
 Security level: Unclassified          │     67 │    11
 Security level: Unclassified          │     68 │     8
 Security level: Unclassified          │     69 │     7
 Security level: Unclassified          │     70 │     5
 Security level: Unclassified          │     71 │     4
 Security level: Unclassified          │     72 │     5
 Security level: Unclassified          │     73 │     7
 Security level: Unclassified          │     74 │     7
 Security level: Unclassified          │     75 │     2
 Security level: Unclassified          │     76 │     5
 Security level: Unclassified          │     77 │     8
 Security level: Unclassified          │     78 │     4
 Security level: Unclassified          │     79 │     5
 Security level: Unclassified          │     80 │     2
 Security level: Unclassified          │     81 │    11
 Security level: Unclassified          │     82 │     4
 Security level: Unclassified          │     83 │     6
 Security level: Unclassified          │     84 │     5
 Security level: Unclassified          │     85 │     1
 Security level: Unclassified          │     86 │     4
 Security level: Unclassified          │     87 │     2
 Security level: Unclassified          │     88 │     8
 Security level: Unclassified          │     89 │     4
 Security level: Unclassified          │     90 │     4
 Security level: Unclassified          │     91 │     4
 Security level: Unclassified          │     92 │     5
 Security level: Unclassified          │     94 │     5
 Security level: Unclassified          │     95 │     7
 Security level: Unclassified          │     96 │     7
 Security level: Unclassified          │     97 │     4
 Security level: Unclassified          │     98 │     4
 Security level: Unclassified          │     99 │     4
 Security level: Unclassified          │    100 │     2
 Security level: Unclassified          │    101 │     1
 Security level: Unclassified          │    102 │     4
 Security level: Unclassified          │    103 │     2
 Security level: Unclassified          │    104 │     9
 Security level: Unclassified          │    105 │     6
 Security level: Unclassified          │    106 │     6
 Security level: Unclassified          │    107 │     2
 Security level: Unclassified          │    108 │     5
 Security level: Unclassified          │    109 │     3
 Security level: Unclassified          │    110 │     4
 Security level: Unclassified          │    111 │     3
 Security level: Unclassified          │    112 │     2
 Security level: Unclassified          │    113 │     5
 Security level: Unclassified          │    115 │     1
 Security level: Unclassified          │    116 │     1
 Security level: Unclassified          │    117 │     2
 Security level: Unclassified          │    118 │     3
 Security level: Unclassified          │    120 │     1
 Security level: Unclassified          │    121 │     3
 Security level: Unclassified          │    122 │     2
 Security level: Unclassified          │    123 │     3
 Security level: Unclassified          │    124 │     1
 Security level: Unclassified          │    127 │     1
 Security level: Unclassified          │    129 │     3
 Security level: Unclassified          │    131 │     1
 Security level: Unclassified          │    133 │     1
 Security level: Unclassified          │    135 │     2
 Security level: Unclassified          │    139 │     1
 Security level: Unclassified          │    140 │     2
 Security level: Unclassified          │    141 │     1
 Security level: Unclassified          │    143 │     1
 Security level: Unclassified          │    145 │     1
 Security level: Unclassified          │    146 │     1
 Security level: Unclassified          │    147 │     1
 Security level: Unclassified          │    149 │     2
 Security level: Unclassified          │    151 │     1
 Security level: Unclassified          │    152 │     2
 Security level: Unclassified          │    153 │     3
 Security level: Unclassified          │    154 │     4
 Security level: Unclassified          │    155 │     2
 Security level: Unclassified          │    156 │     2
 Security level: Unclassified          │    159 │     1
 Security level: Unclassified          │    160 │     2
 Security level: Unclassified          │    161 │     1
 Security level: Unclassified          │    162 │     1
 Security level: Unclassified          │    163 │     1
 Security level: Unclassified          │    167 │     1
 Security level: Unclassified          │    168 │     1
 Security level: Unclassified          │    171 │     1
 Security level: Unclassified          │    176 │     1
 Security level: Unclassified          │    178 │     1
 Security level: Unclassified          │    182 │     1
 Security level: Unclassified          │    183 │     1
 Security level: Unclassified          │    185 │     1
 Security level: Unclassified          │    186 │     1
 Security level: Unclassified          │    187 │     1
 Security level: Unclassified          │    190 │     2
 Security level: Unclassified          │    196 │     1
 Security level: Unclassified          │    202 │     1
 Security level: Unclassified          │    213 │     2
 Security level: Unclassified          │    219 │     2
 Security level: Unclassified          │    223 │     1
 Security level: Unclassified          │    228 │     1
 Security level: Unclassified          │    239 │     1
 Security level: Unclassified          │    240 │     1
 Security level: Unclassified          │    246 │     1
 Security level: Unclassified          │    247 │     1
 Security level: Unclassified          │    267 │     1
 Security level: Unclassified          │    282 │     1
 Security level: Unclassified          │    298 │     1
 Security level: Unclassified          │    323 │     1
 Security level: Unclassified          │    373 │     1
 Security level: Strictly confidential │      1 │   666
 Security level: Strictly confidential │      2 │   520
 Security level: Strictly confidential │      3 │   443
 Security level: Strictly confidential │      4 │   392
 Security level: Strictly confidential │      5 │   360
 Security level: Strictly confidential │      6 │   308
 Security level: Strictly confidential │      7 │   202
 Security level: Strictly confidential │      8 │   183
 Security level: Strictly confidential │      9 │   136
 Security level: Strictly confidential │     10 │   115
 Security level: Strictly confidential │     11 │   114
 Security level: Strictly confidential │     12 │    65
 Security level: Strictly confidential │     13 │    56
 Security level: Strictly confidential │     14 │    46
 Security level: Strictly confidential │     15 │    61
 Security level: Strictly confidential │     16 │    41
 Security level: Strictly confidential │     17 │    26
 Security level: Strictly confidential │     18 │    36
 Security level: Strictly confidential │     19 │    20
 Security level: Strictly confidential │     20 │    28
 Security level: Strictly confidential │     21 │    26
 Security level: Strictly confidential │     22 │    27
 Security level: Strictly confidential │     23 │    24
 Security level: Strictly confidential │     24 │    21
 Security level: Strictly confidential │     25 │    18
 Security level: Strictly confidential │     26 │    17
 Security level: Strictly confidential │     27 │     9
 Security level: Strictly confidential │     28 │    13
 Security level: Strictly confidential │     29 │    10
 Security level: Strictly confidential │     30 │     3
 Security level: Strictly confidential │     31 │     6
 Security level: Strictly confidential │     32 │    11
 Security level: Strictly confidential │     33 │     9
 Security level: Strictly confidential │     34 │     5
 Security level: Strictly confidential │     35 │     5
 Security level: Strictly confidential │     36 │     3
 Security level: Strictly confidential │     37 │     9
 Security level: Strictly confidential │     38 │     7
 Security level: Strictly confidential │     39 │     3
 Security level: Strictly confidential │     40 │     2
 Security level: Strictly confidential │     41 │     3
 Security level: Strictly confidential │     42 │     3
 Security level: Strictly confidential │     43 │     5
 Security level: Strictly confidential │     44 │     6
 Security level: Strictly confidential │     45 │     3
 Security level: Strictly confidential │     46 │     6
 Security level: Strictly confidential │     47 │     4
 Security level: Strictly confidential │     48 │     3
 Security level: Strictly confidential │     49 │     2
 Security level: Strictly confidential │     50 │     4
 Security level: Strictly confidential │     51 │     4
 Security level: Strictly confidential │     53 │     3
 Security level: Strictly confidential │     55 │     3
 Security level: Strictly confidential │     56 │     3
 Security level: Strictly confidential │     57 │     1
 Security level: Strictly confidential │     59 │     1
 Security level: Strictly confidential │     60 │     1
 Security level: Strictly confidential │     61 │     1
 Security level: Strictly confidential │     62 │     1
 Security level: Strictly confidential │     63 │     1
 Security level: Strictly confidential │     67 │     2
 Security level: Strictly confidential │     68 │     1
 Security level: Strictly confidential │     69 │     1
 Security level: Strictly confidential │     70 │     1
 Security level: Strictly confidential │     73 │     1
 Security level: Strictly confidential │     77 │     2
 Security level: Strictly confidential │     79 │     2
 Security level: Strictly confidential │     80 │     2
 Security level: Strictly confidential │     83 │     1
 Security level: Strictly confidential │     87 │     1
 Security level: Strictly confidential │     90 │     1
 Security level: Strictly confidential │     93 │     1
 Security level: Strictly confidential │     94 │     1
 Security level: Strictly confidential │     96 │     2
 Security level: Strictly confidential │    110 │     1
 Security level: Strictly confidential │    112 │     1
 Security level: Strictly confidential │    135 │     1
 Security level: Strictly confidential │    145 │     1
 Security level: Strictly confidential │    151 │     1
 Security level: Strictly confidential │    157 │     1
 Security level: Strictly confidential │    173 │     1
 Security level: Strictly confidential │    177 │     1
 Security level: Strictly confidential │    237 │     1
 Security level: No Security Level     │      1 │    35
 Security level: No Security Level     │      2 │   141
 Security level: No Security Level     │      3 │   128
 Security level: No Security Level     │      4 │   108
 Security level: No Security Level     │      5 │    67
 Security level: No Security Level     │      6 │    49
 Security level: No Security Level     │      7 │    42
 Security level: No Security Level     │      8 │    39
 Security level: No Security Level     │      9 │    26
 Security level: No Security Level     │     10 │    20
 Security level: No Security Level     │     11 │    19
 Security level: No Security Level     │     12 │    17
 Security level: No Security Level     │     13 │    18
 Security level: No Security Level     │     14 │     9
 Security level: No Security Level     │     15 │    16
 Security level: No Security Level     │     16 │    13
 Security level: No Security Level     │     17 │     9
 Security level: No Security Level     │     18 │     9
 Security level: No Security Level     │     19 │     8
 Security level: No Security Level     │     20 │     9
 Security level: No Security Level     │     21 │     6
 Security level: No Security Level     │     23 │     4
 Security level: No Security Level     │     24 │     4
 Security level: No Security Level     │     25 │     3
 Security level: No Security Level     │     27 │     2
 Security level: No Security Level     │     29 │     4
 Security level: No Security Level     │     30 │     6
 Security level: No Security Level     │     31 │     4
 Security level: No Security Level     │     32 │     4
 Security level: No Security Level     │     33 │     4
 Security level: No Security Level     │     35 │     1
 Security level: No Security Level     │     37 │     2
 Security level: No Security Level     │     38 │     1
 Security level: No Security Level     │     39 │     1
 Security level: No Security Level     │     41 │     1
 Security level: No Security Level     │     42 │     1
 Security level: No Security Level     │     43 │     4
 Security level: No Security Level     │     44 │     1
 Security level: No Security Level     │     45 │     1
 Security level: No Security Level     │     46 │     1
 Security level: No Security Level     │     49 │     2
 Security level: No Security Level     │     51 │     1
 Security level: No Security Level     │     54 │     1
 Security level: No Security Level     │     55 │     1
 Security level: No Security Level     │     57 │     1
 Security level: No Security Level     │     61 │     1
 Security level: No Security Level     │     64 │     1
 Security level: No Security Level     │     68 │     2
 Security level: No Security Level     │     70 │     3
 Security level: No Security Level     │     72 │     1
 Security level: No Security Level     │     75 │     1
 Security level: No Security Level     │     76 │     1
 Security level: No Security Level     │     90 │     1
 Security level: No Security Level     │     98 │     1
 Security level: No Security Level     │    100 │     2
 Security level: No Security Level     │    113 │     1
 Security level: No Security Level     │    128 │     1
 Security level: No Security Level     │    151 │     1
 Security level: No Security Level     │    157 │     1
 Security level: Confidential          │      1 │   599
 Security level: Confidential          │      2 │  1230
 Security level: Confidential          │      3 │  1274
 Security level: Confidential          │      4 │  1024
 Security level: Confidential          │      5 │   873
 Security level: Confidential          │      6 │   732
 Security level: Confidential          │      7 │   515
 Security level: Confidential          │      8 │   392
 Security level: Confidential          │      9 │   279
 Security level: Confidential          │     10 │   245
 Security level: Confidential          │     11 │   227
 Security level: Confidential          │     12 │   146
 Security level: Confidential          │     13 │   126
 Security level: Confidential          │     14 │    97
 Security level: Confidential          │     15 │    75
 Security level: Confidential          │     16 │    57
 Security level: Confidential          │     17 │    63
 Security level: Confidential          │     18 │    80
 Security level: Confidential          │     19 │    55
 Security level: Confidential          │     20 │    48
 Security level: Confidential          │     21 │    59
 Security level: Confidential          │     22 │    37
 Security level: Confidential          │     23 │    48
 Security level: Confidential          │     24 │    39
 Security level: Confidential          │     25 │    34
 Security level: Confidential          │     26 │    25
 Security level: Confidential          │     27 │    31
 Security level: Confidential          │     28 │    28
 Security level: Confidential          │     29 │    28
 Security level: Confidential          │     30 │    11
 Security level: Confidential          │     31 │    16
 Security level: Confidential          │     32 │    18
 Security level: Confidential          │     33 │    16
 Security level: Confidential          │     34 │    14
 Security level: Confidential          │     35 │    11
 Security level: Confidential          │     36 │     9
 Security level: Confidential          │     37 │    20
 Security level: Confidential          │     38 │     9
 Security level: Confidential          │     39 │    17
 Security level: Confidential          │     40 │    10
 Security level: Confidential          │     41 │     9
 Security level: Confidential          │     42 │     7
 Security level: Confidential          │     43 │     6
 Security level: Confidential          │     44 │     5
 Security level: Confidential          │     45 │     7
 Security level: Confidential          │     46 │     7
 Security level: Confidential          │     47 │     3
 Security level: Confidential          │     48 │     5
 Security level: Confidential          │     49 │     3
 Security level: Confidential          │     51 │     3
 Security level: Confidential          │     52 │     1
 Security level: Confidential          │     53 │     2
 Security level: Confidential          │     54 │     2
 Security level: Confidential          │     55 │     4
 Security level: Confidential          │     56 │     3
 Security level: Confidential          │     57 │     2
 Security level: Confidential          │     58 │     3
 Security level: Confidential          │     59 │     1
 Security level: Confidential          │     61 │     4
 Security level: Confidential          │     62 │     3
 Security level: Confidential          │     63 │     2
 Security level: Confidential          │     64 │     1
 Security level: Confidential          │     65 │     1
 Security level: Confidential          │     67 │     2
 Security level: Confidential          │     70 │     1
 Security level: Confidential          │     71 │     1
 Security level: Confidential          │     73 │     3
 Security level: Confidential          │     74 │     1
 Security level: Confidential          │     75 │     1
 Security level: Confidential          │     77 │     1
 Security level: Confidential          │     78 │     2
 Security level: Confidential          │     79 │     1
 Security level: Confidential          │     82 │     2
 Security level: Confidential          │     85 │     1
 Security level: Confidential          │     86 │     2
 Security level: Confidential          │     88 │     2
 Security level: Confidential          │     89 │     2
 Security level: Confidential          │     90 │     1
 Security level: Confidential          │     93 │     1
 Security level: Confidential          │     95 │     1
 Security level: Confidential          │     96 │     1
 Security level: Confidential          │     97 │     1
 Security level: Confidential          │    100 │     2
 Security level: Confidential          │    104 │     1
 Security level: Confidential          │    107 │     1
 Security level: Confidential          │    109 │     1
 Security level: Confidential          │    110 │     1
 Security level: Confidential          │    112 │     1
 Security level: Confidential          │    131 │     1
 Security level: Confidential          │    140 │     2
 Security level: Confidential          │    146 │     1
 Security level: Confidential          │    156 │     1
 Security level: Confidential          │    161 │     1
 Security level: Confidential          │    173 │     1
 Security level: Confidential          │    177 │     1
 Security level: Confidential          │    180 │     1
 Security level: Confidential          │    183 │     1
 Security level: Confidential          │    202 │     1
 Security level: Confidential          │    317 │     1
```
### Classification & Title (early look - at least 40 occurrences)
```
~# select rights, title, count(title)                                                                                                                             from un_archives.docs                                                                                                                                              where archtype = 'item' and rights ilike '%confidential%'                                                                                                          group by rights, title                                                                                                                                             having count(title) >= 40                                                                                                                                          order by rights desc, count(title) desc;
                rights                 │                                                      title                                                      │ count
═══════════════════════════════════════╪═════════════════════════════════════════════════════════════════════════════════════════════════════════════════╪═══════
 Security level: Strictly confidential │ Department of Political Affairs (DPA) - Security Council matters - reports on activities                        │   250
 Security level: Strictly confidential │ Code cables sent to the Executive Office of the Secretary-General (EOSG)                                        │   141
 Security level: Strictly confidential │ Academic - schools and universities                                                                             │    66
 Security level: Strictly confidential │ Political affairs - updates on political situations                                                             │    57
 Security level: Strictly confidential │ Department of Peacekeeping Operations (DPKO)                                                                    │    57
 Security level: Strictly confidential │ Miscellaneous organizations - A                                                                                 │    54
 Security level: Strictly confidential │ Political affairs - liaison with the Security Council                                                           │    52
 Security level: Strictly confidential │ Scheduling - invitations to the Secretary-General                                                               │    49
 Security level: Strictly confidential │ Political affairs- reports of the Secretary-General                                                             │    45
 Security level: Strictly confidential │ Political affairs - reports of the Secretary-General                                                            │    44
 Security level: Strictly confidential │ Miscellaneous organizations - I                                                                                 │    42
 Security level: Strictly confidential │ Chronological file                                                                                              │    41
 Security level: Confidential          │ Scheduling - invitations to the Secretary-General                                                               │   775
 Security level: Confidential          │ Political affairs - updates on political situations                                                             │   361
 Security level: Confidential          │ Invitations                                                                                                     │   331
 Security level: Confidential          │ Scheduling - invitations to the Deputy Secretary-General                                                        │   303
 Security level: Confidential          │ Communications and public information - invitations, speeches, and remarks                                      │   267
 Security level: Confidential          │ Peacekeeping - reports of the Secretary-General                                                                 │   247
 Security level: Confidential          │ Code cables sent to the Executive Office of the Secretary-General (EOSG)                                        │   243
 Security level: Confidential          │ Political Unit - update notes for the Secretary-General - annotated                                             │   158
 Security level: Confidential          │ Chronological file                                                                                              │   135
 Security level: Confidential          │ Daily appointments                                                                                              │   133
 Security level: Confidential          │ Political affairs - liaison with the Security Council                                                           │   129
 Security level: Confidential          │ External relations - correspondence of farewell and congratulations (Executive Office of the Secretary-General) │   118
 Security level: Confidential          │ Political affairs - reports of the Secretary-General                                                            │   117
 Security level: Confidential          │ Requests for meetings with the Secretary-General                                                                │   112
 Security level: Confidential          │ Scheduling - requests for meetings with the Secretary-General                                                   │   106
 Security level: Confidential          │ Academic - schools and universities                                                                             │    96
 Security level: Confidential          │ Miscellaneous organizations - A                                                                                 │    91
 Security level: Confidential          │ Miscellaneous organizations - C                                                                                 │    89
 Security level: Confidential          │ Communications and public information - speeches and remarks                                                    │    88
 Security level: Confidential          │ Miscellaneous organizations - I                                                                                 │    85
 Security level: Confidential          │ Invitations - refused, S-T                                                                                      │    79
 Security level: Confidential          │ Invitations - refused, U                                                                                        │    75
 Security level: Confidential          │ Miscellaneous organizations - W                                                                                 │    72
 Security level: Confidential          │ Messages/requests                                                                                               │    71
 Security level: Confidential          │ External relations - member states and observers - incoming correspondence                                      │    68
 Security level: Confidential          │ Executive Office of the Secretary-General (EOSG)                                                                │    68
 Security level: Confidential          │ Department of Peacekeeping Operations (DPKO)                                                                    │    68
 Security level: Confidential          │ Religious organizations                                                                                         │    64
 Security level: Confidential          │ Political affairs - coordination and partnership - conferences, summits, meetings                               │    60
 Security level: Confidential          │ Communications and public information - messages and forewords                                                  │    58
 Security level: Confidential          │ Political affairs - liaison with Security Council                                                               │    57
 Security level: Confidential          │ Political affairs - political unit update notes                                                                 │    56
 Security level: Confidential          │ Peacekeeping - updates on situations                                                                            │    52
 Security level: Confidential          │ Invitations - refused, I                                                                                        │    51
 Security level: Confidential          │ Invitations - refused, I-J                                                                                      │    50
 Security level: Confidential          │ Invitations - refused, J-N                                                                                      │    48
 Security level: Confidential          │ Invitations - refused, K-M                                                                                      │    46
 Security level: Confidential          │ Invitations - refused, N-R                                                                                      │    46
 Security level: Confidential          │ Miscellaneous organizations - F                                                                                 │    45
 Security level: Confidential          │ Human resources and management - Department of Management (DM) - update notes for the Chef de Cabinet (CDC)     │    44
 Security level: Confidential          │ Political affairs- reports of the Secretary-General                                                             │    40
(53 rows)
```
