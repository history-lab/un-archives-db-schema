create schema un_archives;

create unlogged table un_archives.sets (
    oai_id          integer  primary key,
    shortname       text     not null,
    fullname        text     not null
    );
insert into un_archives.sets values (465279,'moon','Secretary-General Ban Ki-moon (2007-2016)');
insert into un_archives.sets values (223075,'annan','Secretary-General Kofi Annan (1997-2006)');

create unlogged table un_archives.metadata (
    oai_id          integer     primary key,
    oai_timestamp   timestamptz not null,
    oai_set         integer     not null references un_archives.sets,
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
                    references  un_archives.metadata,
    pg_cnt          integer     not null,
    size            integer     not null
    );
comment on column un_archives.pdfs.size is 'Size of PDF in bytes';

create unlogged table un_archives.pdfpages (
    oai_id          integer     not null
                    references  un_archives.metadata,
    pg              integer     not null,
    word_cnt        integer     not null,
    char_cnt        integer     not null,
    body            text,
    primary key (oai_id, pg)
    );

create or replace view un_archives.docs as
select m.oai_id id, s.shortname setname,
   dc_title title, dc_creator creator, dc_description description,
   dc_rights rights, dc_identifier_uri uri, dc_identifier_sid sid,
   case when length(dc_identifier_sid) - length(replace(dc_identifier_sid, '-', '')) = 1 then
            case when dc_identifier_sid like 'S-%' then 'series'
                 else                     'fond'
            end
        when length(dc_identifier_sid) - length(replace(dc_identifier_sid, '-', '')) = 2 then
            case when dc_identifier_sid like 'S-%' then 'box'
                 else                     'subfond'
            end
        when length(dc_identifier_sid) - length(replace(dc_identifier_sid, '-', '')) = 3 then 'folder'
        when length(dc_identifier_sid) - length(replace(dc_identifier_sid, '-', '')) = 4 then 'item'
        else '** unknown **'
    end archtype, has_doc, jpg_url, pdf_url, 
    size, pg_cnt, sum(word_cnt) word_cnt, sum(char_cnt) char_cnt,
    string_agg(body, chr(10) order by pg) body
from un_archives.metadata m
    join un_archives.sets s on           (m.oai_set = s.oai_id)
    left join un_archives.pdfs p on      (m.oai_id = p.oai_id)
    left join un_archives.pdfpages pp on (p.oai_id = pp.oai_id)
group by id, setname, title, creator, description, rights, uri, sid,
         has_doc, jpg_url, pdf_url, size, pg_cnt;

-- API access
create or replace view foiarchive.un_archives_docs as
select * from un_archives.docs;
great select on un_archives_docs to web_anon;
-- grant usage on schema un_archives to web_anon;
-- grant select on un_archives.docs to web_anon;

-- select id, title, creator, description, rights, pdf_url, pg_cnt, size, word_cnt, char_cnt, body from un_archives.docs where body is not null;
