insert into un_archives.fonds
    (fond_id, un_id, shortname, title, creator, description,
     rights, url, record_created)
select m.oai_id, dc_identifier_sid, s.shortname, dc_title, dc_creator,
       dc_description, dc_rights, dc_identifier_uri, oai_timestamp
    from un_archives.metadata m join un_archives.sets s
        on (m.oai_set = s.oai_id)
    where length(dc_identifier_sid) =
            length(replace(dc_identifier_sid, '-', '')) + 1 and
          dc_identifier_sid not like 'S-%';

insert into un_archives.subfonds
  (subfond_id, un_id, title, creator, description,
   rights, url, record_created, fond_id)
select m.oai_id, dc_identifier_sid, dc_title, dc_creator, dc_description,
       dc_rights, dc_identifier_uri, oai_timestamp,
       (select fond_id from un_archives.fonds
           where un_id = substring(dc_identifier_sid, 1, 6))
  from un_archives.metadata m join un_archives.sets s
      on (m.oai_set = s.oai_id)
  where length(dc_identifier_sid) =
          length(replace(dc_identifier_sid, '-', '')) + 2 and
        dc_identifier_sid not like 'S-%';

-- series
insert into un_archives.series
  (series_id, un_id, title, creator, description,
   url, record_created, fond_id)
select m.oai_id, dc_identifier_sid, dc_title, dc_creator, dc_description,
       dc_identifier_uri, oai_timestamp, m.oai_set
  from un_archives.metadata m join un_archives.sets s
      on (m.oai_set = s.oai_id)
  where length(dc_identifier_sid) =
          length(replace(dc_identifier_sid, '-', '')) + 1 and
        dc_identifier_sid like 'S-%';

-- folder
insert into un_archives.folders
  (folder_id, un_id, series_id,
   title, description, url, classification, record_created)
select m.oai_id, m.dc_identifier_sid,
       (select series_id from un_archives.series
           where un_id = substring(m.dc_identifier_sid, 1, 6)),
       dc_title, dc_description, dc_identifier_uri,
       substring(lower(dc_rights), 17), oai_timestamp
  from un_archives.metadata m join un_archives.sets s
      on (m.oai_set = s.oai_id)
  where length(dc_identifier_sid) =
          length(replace(dc_identifier_sid, '-', '')) + 3 and
        dc_identifier_sid like 'S-%';
