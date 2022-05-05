create schema un_archives;

create unlogged table un_archives.metadata_load (
    oai_id          integer     primary key,
    oai_timestamp   timestamptz not null,
    oai_set         integer     not null  /* TBD add set table */,
    dc_title        text        not null,
    dc_creator      text        not null,
    dc_description  text        null,
    dc_rights       text        null,
    dc_identifier_uri   text    not null,
    dc_identifier_sid   text    not null,
    has_doc         boolean     not null,
    pdf_url         text,
    jpg_url         text
    );

\copy un_archives.metadata_load from '/Users/benjaminlis/history-lab/oaiharvester/safe/oahr.csv' delimiter ',' csv header

create unlogged table un_archives.pdfs (
    oai_id          integer     primary key
                    references  un_archives.metadata_load,
    pg_cnt          integer     not null,
    size            integer     not null
    );
comment on column un_archives.pdfs.size is 'Size of PDF in bytes';

create unlogged table un_archives.pdfpages (
    oai_id          integer     not null
                    references  un_archives.metadata_load,
    pg              integer     not null,
    word_cnt        integer     not null,
    char_cnt        integer     not null,
    body            text,
    primary key (oai_id, pg)
    );

create or replace view un_archives.docs as
select m.oai_id id, 'moon' subcollection,
   dc_title title, dc_creator creator, dc_description description,
   dc_rights rights, dc_identifier_uri uri, dc_identifier_sid sid, has_doc,
   jpg_url, pdf_url, size, pg_cnt, sum(word_cnt) word_cnt, sum(char_cnt) char_cnt,
   string_agg(body, chr(10) order by pg) body
from un_archives.metadata_load m
    left join un_archives.pdfs p on      (m.oai_id = p.oai_id)
    left join un_archives.pdfpages pp on (p.oai_id = pp.oai_id)
group by id, subcollection, title, creator, description, rights, uri, sid,
         has_doc, jpg_url, pdf_url, size, pg_cnt;

-- select id, title, creator, description, rights, pdf_url, pg_cnt, size, word_cnt, char_cnt, body from un_archives.docs where body is not null;
