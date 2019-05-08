-- data mock ------------------------------------------------------------------

CREATE TABLE subnet (
  ip TEXT,
  netmask TEXT,

  PRIMARY KEY (ip, netmask)
);
CREATE TABLE ip (
  ip TEXT,
  name TEXT,

  PRIMARY KEY (ip)
);

INSERT INTO subnet (ip, netmask)
VALUES
  ('192.168.1.1', '255.255.255.0'),
  ('192.168.1.1', '255.255.0.0'),
  ('10.0.0.0', '255.0.0.0'),
  ('192.168.1.21', '255.255.255.255');

INSERT INTO ip (ip, name)
VALUES
  ('192.168.1.21', 'Class C'),
  ('172.16.0.1', 'Class B'),
  ('10.0.0.1', 'Class A'),
  ('10.1.0.1', 'Class A'),
  ('1.1.1.1', 'Public'),
  ('8.8.8.8', 'Public');

-- table definition modification ----------------------------------------------

ALTER TABLE subnet
  ADD ip_int INTEGER;
ALTER TABLE subnet
  ADD netmask_shift INTEGER;

ALTER TABLE ip
  ADD ip_int INTEGER;

-- actual stuff ---------------------------------------------------------------

CREATE TABLE __pow_of_2 (
  num INTEGER,
  pow INTEGER,

  PRIMARY KEY (num)
);
INSERT INTO __pow_of_2 (num, pow)
VALUES 
  (0, 1), 
  (1, 2), (2, 4), (3, 8), (4, 16), (5, 32), (6, 64), (7, 128), (8, 256),
  (9, 512), (10, 1024), (11, 2048), (12, 4096), (13, 8192), (14, 16384),
  (15, 32768), (16, 65536),
  (17, 131072), (18, 262144), (19, 524288), (20, 1048576), (21, 2097152),
  (22, 4194304), (23, 8388608), (24, 16777216),
  (25, 33554432), (26, 67108864), (27, 134217728), (28, 268435456),
  (29, 536870912), (30, 1073741824), (31, 2147483648), (32, 4294967296);

UPDATE ip
SET ip_int = (
  SELECT (CAST(o4 AS INTEGER) << 24) | (CAST(o3 AS INTEGER) << 16) |
         (CAST(substr(ip, 0, instr(ip, '.')) AS INTEGER) << 8) |
         (CAST(substr(ip, instr(ip, '.') + 1) AS INTEGER))
  FROM (
    SELECT o4, substr(ip, 0, instr(ip, '.')) AS o3,
               substr(ip, instr(ip, '.') + 1) AS ip
    FROM (
      SELECT substr(ip, 0, instr(ip, '.')) AS o4,
             substr(ip, instr(ip, '.') + 1) AS ip
    )
  )
);

UPDATE subnet
SET ip_int = (
  SELECT (CAST(o4 AS INTEGER) << 24) | (CAST(o3 AS INTEGER) << 16) |
         (CAST(substr(ip, 0, instr(ip, '.')) AS INTEGER) << 8) |
         (CAST(substr(ip, instr(ip, '.') + 1) AS INTEGER))
  FROM (
    SELECT o4, substr(ip, 0, instr(ip, '.')) AS o3,
               substr(ip, instr(ip, '.') + 1) AS ip
    FROM (
      SELECT substr(ip, 0, instr(ip, '.')) AS o4,
             substr(ip, instr(ip, '.') + 1) AS ip
    )
  )
),
    netmask_shift = (
  SELECT 32 - p.num
  FROM (
    SELECT (CAST(o4 AS INTEGER) << 24) | (CAST(o3 AS INTEGER) << 16) |
           (CAST(substr(netmask, 0, instr(netmask, '.')) AS INTEGER) << 8) |
           (CAST(substr(netmask, instr(netmask, '.') + 1) AS INTEGER)) AS sn
    FROM (
      SELECT o4, substr(netmask, 0, instr(netmask, '.')) AS o3,
                 substr(netmask, instr(netmask, '.') + 1) AS netmask
      FROM (
        SELECT substr(netmask, 0, instr(netmask, '.')) AS o4,
               substr(netmask, instr(netmask, '.') + 1) AS netmask
      )
    )
  ) AS s
  LEFT JOIN __pow_of_2 AS p
  ON (0xFFFFFFFF | s.sn) - (0xFFFFFFFF & s.sn) + 1 = p.pow 
);

-- and here we are -------------------------------------------------------------

SELECT i.name, i.ip AS ip_addr, 
	     s.ip AS subnet_addr, s.netmask AS subnet_netmask,
	     s.ip || "/" || s.netmask_shift AS subnet_cidr
FROM ip AS i
LEFT JOIN subnet AS s
ON (i.ip_int >> (32 - s.netmask_shift)) = (s.ip_int >> (32 - s.netmask_shift));
