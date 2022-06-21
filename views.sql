create or replace view un_archives.docs as
select i.item_id doc_id, i.item_id, i.folder_id, i.series_id, s.fond_id,
       i.un_id, f.un_id folder_un_id, s.un_id series_un_id, fn.un_id fond_un_id,
       fn.shortname fond_shortname, s.creator,
       i.title, f.title folder_title, s.title series_title, fn.title fond_title,
       f.description folder_description, s.description series_description,
       i.url, i.pdf_url, f.url folder_url, s.url series_url, fn.url fond_url,
       i.classification, f.classification folder_classification,
       p.size pdf_size_bytes, p.pg_cnt, pp.word_cnt, pp.char_cnt, body
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
                            on (i.item_id = pp.item_id);
