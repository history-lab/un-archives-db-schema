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

create unlogged table un_archives.pdfs (
    oai_id          integer     primary key
                    references  un_archives.metadata_load,
    pg_cnt          integer     not null,
    word_cnt        integer     not null,
    size            integer     not null,
    body            text        not null
    );
comment on column un_archives.docs.size is 'Size of text body in bytes';

\copy un_archives.metadata_load from '/Users/benjaminlis/history-lab/oaiharvester/safe/oahr.csv' delimiter ',' csv header
