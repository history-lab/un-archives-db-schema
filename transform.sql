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
