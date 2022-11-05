create or replace view un_archives.docs as
select i.item_id doc_id, i.item_id, i.folder_id, i.series_id, s.fond_id,
       i.un_id, f.un_id folder_un_id, s.un_id series_un_id, fn.un_id fond_un_id,
       fn.shortname fond_shortname, s.creator,
       i.title, f.title folder_title, s.title series_title, fn.title fond_title,
       f.description folder_description, s.description series_description,
       i.url, i.pdf_url, f.url folder_url, s.url series_url, fn.url fond_url,
       i.classification, f.classification folder_classification,
       p.size pdf_size_bytes, p.pg_cnt, pp.word_cnt, pp.char_cnt, body,
       l.doc_lang, l.score doc_lang_score, d.doc_date
from un_archives.items i join un_archives.series s
                            on (i.series_id = s.series_id)
                         join un_archives.fonds fn
                            on (s.fond_id = fn.fond_id)
                         left join un_archives.folders f
                            on (i.folder_id = f.folder_id)
                         left join un_archives.pdfs p
                            on (i.item_id = p.item_id)
                         left join (select item_id,
                                           string_agg(body, chr(10) order by pg)
                                                         body,
                                           sum(word_cnt) word_cnt,
                                           sum(char_cnt) char_cnt
                                       from un_archives.pdfpages
                                       group by item_id) pp
                            on (i.item_id = pp.item_id)
                          join un_archives.doc_lang_temp l
                            on (i.item_id = l.item_id)
                          left join un_archives.doc_date_temp d
                            on (i.item_id = d.item_id);

create or replace view foiarchive.un_archives_docs as
select * from un_archives.docs;
grant select on foiarchive.un_archives_docs to web_anon, c19ro;

create or replace view un_archives.temp_metadata_view as
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
    left join un_archives.pdfs p on      (m.oai_id = p.item_id)
    left join un_archives.pdfpages pp on (p.item_id = pp.item_id)
group by id, setname, title, creator, description, rights, uri, sid,
         has_doc, jpg_url, pdf_url, size, pg_cnt;
