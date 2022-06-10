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
