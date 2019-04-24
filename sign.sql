SELECT s."val",
 (case when s."val" like '%;%'
       then left(s."val", charindex(';', s."val") - 1)
       else s."val"
  end) as ttn
FROM [PROGRESS].[NS2000L].[PUB].[sign] as s
WHERE s."sign-net"=44
AND s."sign-num"=32111190
