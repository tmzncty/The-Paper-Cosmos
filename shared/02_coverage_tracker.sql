-- ============================================================
-- 《纸上宇宙》考研知识点覆盖追踪系统
-- 数据库：postgres | Schema：kaoyan
-- 设计目标：追踪 4,526 条知识点融入轻小说的进度
-- ============================================================

-- 创建 schema（如果不存在）
CREATE SCHEMA IF NOT EXISTS kaoyan;

-- ============================================================
-- 1. 分类维度表
-- ============================================================

-- 主题域表
CREATE TABLE IF NOT EXISTS kaoyan.taxonomy_subject (
    code        VARCHAR(10) PRIMARY KEY,
    name        VARCHAR(50) NOT NULL,
    parent_code VARCHAR(10) REFERENCES kaoyan.taxonomy_subject(code),
    description TEXT,
    sort_order  INTEGER DEFAULT 0
);

INSERT INTO kaoyan.taxonomy_subject (code, name, description, sort_order) VALUES
    ('ANC', '中国古代文学', '先秦至清代的中国古典文学', 1),
    ('MOD', '中国现当代文学', '1917年至今的中国文学', 2),
    ('FOR', '外国文学', '古希腊罗马至20世纪的欧洲及世界文学', 3),
    ('THE', '文学理论', '文学本质、创作、作品、接受、批评', 4),
    ('BIB', '文献学', '目录、版本、校勘、辑佚、辨伪', 5),
    ('LEC', '课程笔记综合', 'CCTalk 大牛课、100词、专题串讲', 6),
    ('META', '元数据', '封面、目录、版权页等非知识点内容', 99)
ON CONFLICT (code) DO UPDATE SET name = EXCLUDED.name;

-- 子域表
CREATE TABLE IF NOT EXISTS kaoyan.taxonomy_subdomain (
    code         VARCHAR(20) PRIMARY KEY,
    parent_code  VARCHAR(10) NOT NULL REFERENCES kaoyan.taxonomy_subject(code),
    name         VARCHAR(100) NOT NULL,
    description  TEXT,
    sort_order   INTEGER DEFAULT 0
);

INSERT INTO kaoyan.taxonomy_subdomain (code, parent_code, name, sort_order) VALUES
    ('ANC-01', 'ANC', '先秦文学', 1),
    ('ANC-02', 'ANC', '秦汉文学', 2),
    ('ANC-03', 'ANC', '魏晋南北朝文学', 3),
    ('ANC-04', 'ANC', '隋唐五代文学', 4),
    ('ANC-05', 'ANC', '宋代文学', 5),
    ('ANC-06', 'ANC', '元代文学', 6),
    ('ANC-07', 'ANC', '明清文学', 7),
    ('MOD-01', 'MOD', '现代文学（1917-1949）', 1),
    ('MOD-02', 'MOD', '当代文学（1949-至今）', 2),
    ('FOR-01', 'FOR', '古希腊罗马文学', 1),
    ('FOR-02', 'FOR', '中世纪文学', 2),
    ('FOR-03', 'FOR', '文艺复兴文学', 3),
    ('FOR-04', 'FOR', '17世纪文学', 4),
    ('FOR-05', 'FOR', '18世纪文学', 5),
    ('FOR-06', 'FOR', '19世纪文学', 6),
    ('FOR-07', 'FOR', '20世纪文学', 7),
    ('THE-01', 'THE', '文学本质论', 1),
    ('THE-02', 'THE', '文学创作与作品论', 2),
    ('THE-03', 'THE', '文学接受与批评论', 3),
    ('BIB-01', 'BIB', '目录学', 1),
    ('BIB-02', 'BIB', '版本学', 2),
    ('BIB-03', 'BIB', '校勘学', 3),
    ('BIB-04', 'BIB', '辑佚与辨伪', 4),
    ('LEC-01', 'LEC', '大牛课专题', 1),
    ('LEC-02', 'LEC', '100词速记', 2),
    ('LEC-03', 'LEC', '专题串讲', 3)
ON CONFLICT (code) DO UPDATE SET name = EXCLUDED.name;

-- 时代域表
CREATE TABLE IF NOT EXISTS kaoyan.taxonomy_period (
    code        VARCHAR(20) PRIMARY KEY,
    name        VARCHAR(50) NOT NULL,
    parent_code VARCHAR(10) REFERENCES kaoyan.taxonomy_subject(code),
    year_start  INTEGER,
    year_end    INTEGER,
    description TEXT
);

INSERT INTO kaoyan.taxonomy_period (code, name, parent_code, year_start, year_end) VALUES
    ('CN-PRE',     '先秦',         'ANC', -3000, -221),
    ('CN-QIN',     '秦汉',         'ANC', -221,  220),
    ('CN-WEI',     '魏晋南北朝',   'ANC', 220,   589),
    ('CN-SUI',     '隋唐五代',     'ANC', 581,   960),
    ('CN-SONG',    '宋代',         'ANC', 960,   1279),
    ('CN-YUAN',    '元代',         'ANC', 1271,  1368),
    ('CN-MING',    '明代',         'ANC', 1368,  1644),
    ('CN-QING',    '清代',         'ANC', 1644,  1912),
    ('CN-MODERN',  '现代',         'MOD', 1917,  1949),
    ('CN-CONTEMP', '当代',         'MOD', 1949,  2026),
    ('EU-ANCIENT', '古希腊罗马',   'FOR', -800,  476),
    ('EU-MEDIEVAL','中世纪',       'FOR', 476,   1400),
    ('EU-RENAISS', '文艺复兴',     'FOR', 1400,  1600),
    ('EU-C17',     '17世纪',       'FOR', 1600,  1700),
    ('EU-C18',     '18世纪',       'FOR', 1700,  1800),
    ('EU-C19',     '19世纪',       'FOR', 1800,  1900),
    ('EU-C20',     '20世纪',       'FOR', 1900,  2000)
ON CONFLICT (code) DO UPDATE SET name = EXCLUDED.name;

-- 知识点类型表
CREATE TABLE IF NOT EXISTS kaoyan.taxonomy_ktype (
    code        VARCHAR(20) PRIMARY KEY,
    name        VARCHAR(50) NOT NULL,
    description TEXT,
    novel_hint  TEXT
);

INSERT INTO kaoyan.taxonomy_ktype (code, name, novel_hint) VALUES
    ('AUTH',      '作家生平',     '适合写成角色传记、对话回忆'),
    ('WORK',      '代表作品',     '适合嵌入情节主线、伏笔'),
    ('GENRE',     '文体/流派',    '适合设定阵营、门派'),
    ('MOVEMENT',  '思潮/运动',    '适合世界观背景设定'),
    ('CONCEPT',   '理论概念',     '适合写成"技能体系"、"修炼功法"'),
    ('CRITIC',    '批评方法',     '适合写成"鉴定术"、"解析能力"'),
    ('TEXT',      '原文引用',     '适合直接嵌入对话、信件、日记'),
    ('HIST',      '历史背景',     '适合写成世界观历史、编年史'),
    ('EXAM',      '考点/真题',    '适合写成关键剧情节点、转折点'),
    ('NOTE',      '课程笔记',     '适合写成角色之间的"秘传心得"')
ON CONFLICT (code) DO UPDATE SET name = EXCLUDED.name;

-- ============================================================
-- 2. 统一知识点表（合并 chunks + cctalk_chunks + exam_questions）
-- ============================================================

CREATE TABLE IF NOT EXISTS kaoyan.knowledge_points (
    id              SERIAL PRIMARY KEY,
    
    -- 来源信息
    source_table    VARCHAR(30) NOT NULL,
    source_id       INTEGER NOT NULL,
    
    -- 分类标签
    subject_code    VARCHAR(10) REFERENCES kaoyan.taxonomy_subject(code),
    subdomain_code  VARCHAR(20) REFERENCES kaoyan.taxonomy_subdomain(code),
    period_code     VARCHAR(20) REFERENCES kaoyan.taxonomy_period(code),
    ktype_code      VARCHAR(20) REFERENCES kaoyan.taxonomy_ktype(code),
    
    -- 内容摘要
    title           VARCHAR(500),
    content_preview TEXT,
    
    -- 难度与重要度
    difficulty      SMALLINT DEFAULT 1 CHECK (difficulty BETWEEN 1 AND 5),
    importance      SMALLINT DEFAULT 2 CHECK (importance BETWEEN 0 AND 3),
    
    -- 计算字段
    weight_score    NUMERIC(5,2) GENERATED ALWAYS AS (
        (4.0 - importance) * (1 + difficulty * 0.3)
    ) STORED,
    
    -- 元数据
    tags            TEXT[],
    created_at      TIMESTAMP DEFAULT NOW(),
    updated_at      TIMESTAMP DEFAULT NOW(),
    
    UNIQUE (source_table, source_id)
);

CREATE INDEX IF NOT EXISTS idx_kp_source ON kaoyan.knowledge_points(source_table, source_id);
CREATE INDEX IF NOT EXISTS idx_kp_subject ON kaoyan.knowledge_points(subject_code);
CREATE INDEX IF NOT EXISTS idx_kp_subdomain ON kaoyan.knowledge_points(subdomain_code);
CREATE INDEX IF NOT EXISTS idx_kp_period ON kaoyan.knowledge_points(period_code);
CREATE INDEX IF NOT EXISTS idx_kp_ktype ON kaoyan.knowledge_points(ktype_code);
CREATE INDEX IF NOT EXISTS idx_kp_importance ON kaoyan.knowledge_points(importance);
CREATE INDEX IF NOT EXISTS idx_kp_tags ON kaoyan.knowledge_points USING GIN(tags);

-- ============================================================
-- 3. 覆盖追踪表（核心）
-- ============================================================

CREATE TABLE IF NOT EXISTS kaoyan.coverage_tracker (
    id              SERIAL PRIMARY KEY,
    
    -- 关联知识点
    knowledge_id    INTEGER NOT NULL REFERENCES kaoyan.knowledge_points(id) ON DELETE CASCADE,
    
    -- 小说融入信息
    novel_chapter   INTEGER,
    novel_chapter_title VARCHAR(200),
    novel_paragraph INTEGER,
    novel_volume    SMALLINT,
    
    -- 融入方式
    integration_method VARCHAR(30) NOT NULL CHECK (integration_method IN (
        'dialogue',     -- 对话：角色之间的讨论
        'plot',         -- 情节：融入主线情节
        'description',  -- 描写：环境、场景描写
        'narration',    -- 旁白：作者叙述
        'monologue',    -- 独白：角色内心独白
        'letter',       -- 书信：信件、日记
        'in_world_doc', -- 异世界文献：设定中的书籍、碑文
        'skill_system', -- 技能系统：修炼、技能描述
        'world_history',-- 世界观历史：编年史、大事记
        'annotation',   -- 注释：章节末尾注释
        'other'         -- 其他
    )),
    
    -- 融入质量
    quality_score   SMALLINT CHECK (quality_score BETWEEN 1 AND 10),
    quality_notes   TEXT,
    
    -- 融入效果
    integration_depth VARCHAR(20) CHECK (integration_depth IN (
        'surface',      -- 表面：简单提及
        'moderate',     -- 中等：有一定展开
        'deep',         -- 深入：充分融入情节
        'core'          -- 核心：成为关键情节要素
    )),
    
    -- 融入内容
    novel_excerpt   TEXT,
    source_excerpt  TEXT,
    
    -- 状态追踪
    status          VARCHAR(20) NOT NULL DEFAULT 'pending' CHECK (status IN (
        'pending',      -- 未融入
        'draft',        -- 草稿中
        'review',       -- 待审核
        'approved',     -- 已审核通过
        'revision',     -- 需要修改
        'rejected'      -- 已拒绝
    )),
    
    -- 审核信息
    reviewer        VARCHAR(100),
    reviewed_at     TIMESTAMP,
    review_notes    TEXT,
    
    -- 元数据
    created_at      TIMESTAMP DEFAULT NOW(),
    updated_at      TIMESTAMP DEFAULT NOW(),
    
    UNIQUE (knowledge_id, novel_chapter, novel_paragraph)
);

CREATE INDEX IF NOT EXISTS idx_ct_knowledge ON kaoyan.coverage_tracker(knowledge_id);
CREATE INDEX IF NOT EXISTS idx_ct_chapter ON kaoyan.coverage_tracker(novel_chapter);
CREATE INDEX IF NOT EXISTS idx_ct_status ON kaoyan.coverage_tracker(status);
CREATE INDEX IF NOT EXISTS idx_ct_method ON kaoyan.coverage_tracker(integration_method);
CREATE INDEX IF NOT EXISTS idx_ct_quality ON kaoyan.coverage_tracker(quality_score);

-- ============================================================
-- 4. 小说章节表
-- ============================================================

CREATE TABLE IF NOT EXISTS kaoyan.novel_chapters (
    chapter_number  INTEGER PRIMARY KEY,
    chapter_title   VARCHAR(200) NOT NULL,
    volume          SMALLINT,
    word_count      INTEGER,
    synopsis        TEXT,
    main_characters TEXT[],
    themes          TEXT[],
    status          VARCHAR(20) DEFAULT 'planned' CHECK (status IN (
        'planned', 'drafting', 'completed', 'revised', 'published'
    )),
    created_at      TIMESTAMP DEFAULT NOW(),
    updated_at      TIMESTAMP DEFAULT NOW()
);

-- ============================================================
-- 5. 触发器：自动更新 updated_at
-- ============================================================

CREATE OR REPLACE FUNCTION kaoyan.update_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_kp_updated ON kaoyan.knowledge_points;
CREATE TRIGGER trg_kp_updated
    BEFORE UPDATE ON kaoyan.knowledge_points
    FOR EACH ROW EXECUTE FUNCTION kaoyan.update_timestamp();

DROP TRIGGER IF EXISTS trg_ct_updated ON kaoyan.coverage_tracker;
CREATE TRIGGER trg_ct_updated
    BEFORE UPDATE ON kaoyan.coverage_tracker
    FOR EACH ROW EXECUTE FUNCTION kaoyan.update_timestamp();

DROP TRIGGER IF EXISTS trg_nc_updated ON kaoyan.novel_chapters;
CREATE TRIGGER trg_nc_updated
    BEFORE UPDATE ON kaoyan.novel_chapters
    FOR EACH ROW EXECUTE FUNCTION kaoyan.update_timestamp();

-- ============================================================
-- 6. 覆盖率统计视图
-- ============================================================

-- 总体覆盖率视图
CREATE OR REPLACE VIEW kaoyan.v_coverage_summary AS
SELECT
    s.code AS subject_code,
    s.name AS subject_name,
    COUNT(DISTINCT kp.id) AS total_points,
    COUNT(DISTINCT CASE WHEN ct.status IN ('approved', 'review') THEN kp.id END) AS covered_points,
    COUNT(DISTINCT CASE WHEN ct.status = 'approved' THEN kp.id END) AS approved_points,
    COUNT(DISTINCT CASE WHEN ct.status = 'draft' THEN kp.id END) AS draft_points,
    COUNT(DISTINCT CASE WHEN ct.status = 'pending' OR ct.id IS NULL THEN kp.id END) AS pending_points,
    ROUND(
        COUNT(DISTINCT CASE WHEN ct.status IN ('approved', 'review') THEN kp.id END)::NUMERIC 
        / NULLIF(COUNT(DISTINCT kp.id), 0) * 100, 
        2
    ) AS coverage_pct
FROM kaoyan.knowledge_points kp
JOIN kaoyan.taxonomy_subject s ON kp.subject_code = s.code
LEFT JOIN kaoyan.coverage_tracker ct ON kp.id = ct.knowledge_id
GROUP BY s.code, s.name
ORDER BY s.sort_order;

-- 按融入方式统计视图
CREATE OR REPLACE VIEW kaoyan.v_integration_methods AS
SELECT
    integration_method,
    COUNT(*) AS count,
    ROUND(AVG(quality_score), 2) AS avg_quality,
    COUNT(CASE WHEN status = 'approved' THEN 1 END) AS approved_count
FROM kaoyan.coverage_tracker
WHERE status != 'pending'
GROUP BY integration_method
ORDER BY count DESC;

-- 按章节统计视图
CREATE OR REPLACE VIEW kaoyan.v_chapter_coverage AS
SELECT
    nc.chapter_number,
    nc.chapter_title,
    nc.volume,
    COUNT(DISTINCT ct.knowledge_id) AS knowledge_count,
    COUNT(DISTINCT kp.subject_code) AS subject_diversity,
    ROUND(AVG(ct.quality_score), 2) AS avg_quality,
    ARRAY_AGG(DISTINCT kp.subject_code ORDER BY kp.subject_code) AS subjects_covered
FROM kaoyan.novel_chapters nc
LEFT JOIN kaoyan.coverage_tracker ct ON nc.chapter_number = ct.novel_chapter
LEFT JOIN kaoyan.knowledge_points kp ON ct.knowledge_id = kp.id
GROUP BY nc.chapter_number, nc.chapter_title, nc.volume
ORDER BY nc.chapter_number;

-- 未覆盖知识点视图（优先级排序）
CREATE OR REPLACE VIEW kaoyan.v_uncovered_points AS
SELECT
    kp.id,
    kp.title,
    s.name AS subject_name,
    sd.name AS subdomain_name,
    p.name AS period_name,
    kt.name AS ktype_name,
    kp.difficulty,
    kp.importance,
    kp.weight_score
FROM kaoyan.knowledge_points kp
JOIN kaoyan.taxonomy_subject s ON kp.subject_code = s.code
LEFT JOIN kaoyan.taxonomy_subdomain sd ON kp.subdomain_code = sd.code
LEFT JOIN kaoyan.taxonomy_period p ON kp.period_code = p.code
JOIN kaoyan.taxonomy_ktype kt ON kp.ktype_code = kt.code
WHERE NOT EXISTS (
    SELECT 1 FROM kaoyan.coverage_tracker ct 
    WHERE ct.knowledge_id = kp.id AND ct.status IN ('approved', 'review')
)
ORDER BY kp.importance ASC, kp.weight_score DESC;

-- ============================================================
-- 7. 便捷查询函数
-- ============================================================

-- 获取某章节的知识点覆盖详情
CREATE OR REPLACE FUNCTION kaoyan.get_chapter_coverage(p_chapter INTEGER)
RETURNS TABLE(
    knowledge_id INTEGER,
    title VARCHAR,
    subject VARCHAR,
    method VARCHAR,
    quality SMALLINT,
    status VARCHAR,
    excerpt TEXT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        ct.knowledge_id,
        kp.title,
        s.name,
        ct.integration_method,
        ct.quality_score,
        ct.status,
        ct.novel_excerpt
    FROM kaoyan.coverage_tracker ct
    JOIN kaoyan.knowledge_points kp ON ct.knowledge_id = kp.id
    JOIN kaoyan.taxonomy_subject s ON kp.subject_code = s.code
    WHERE ct.novel_chapter = p_chapter
    ORDER BY ct.novel_paragraph NULLS LAST;
END;
$$ LANGUAGE plpgsql;

-- 获取某主题域的未覆盖核心知识点
CREATE OR REPLACE FUNCTION kaoyan.get_uncovered_core(p_subject VARCHAR)
RETURNS TABLE(
    knowledge_id INTEGER,
    title VARCHAR,
    subdomain VARCHAR,
    period VARCHAR,
    ktype VARCHAR,
    weight NUMERIC
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        kp.id,
        kp.title,
        sd.name,
        p.name,
        kt.name,
        kp.weight_score
    FROM kaoyan.knowledge_points kp
    LEFT JOIN kaoyan.taxonomy_subdomain sd ON kp.subdomain_code = sd.code
    LEFT JOIN kaoyan.taxonomy_period p ON kp.period_code = p.code
    JOIN kaoyan.taxonomy_ktype kt ON kp.ktype_code = kt.code
    WHERE kp.subject_code = p_subject
      AND kp.importance <= 1
      AND NOT EXISTS (
          SELECT 1 FROM kaoyan.coverage_tracker ct 
          WHERE ct.knowledge_id = kp.id AND ct.status IN ('approved', 'review')
      )
    ORDER BY kp.weight_score DESC
    LIMIT 50;
END;
$$ LANGUAGE plpgsql;

-- ============================================================
-- 8. 数据导入模板（需配合分类脚本使用）
-- ============================================================

/*
-- 从 chunks 表批量导入
INSERT INTO kaoyan.knowledge_points 
    (source_table, source_id, subject_code, subdomain_code, period_code, ktype_code, title, content_preview, difficulty, importance, tags)
SELECT
    'chunks',
    c.id,
    CASE s.category
        WHEN 'textbook' THEN 
            CASE 
                WHEN s.title LIKE '%古代%' THEN 'ANC'
                WHEN s.title LIKE '%现代%' OR s.title LIKE '%当代%' THEN 'MOD'
                WHEN s.title LIKE '%欧洲%' THEN 'FOR'
                WHEN s.title LIKE '%理论%' THEN 'THE'
                WHEN s.title LIKE '%文献%' THEN 'BIB'
                ELSE 'META'
            END
        ELSE 'META'
    END,
    NULL, NULL, 'TEXT',
    SUBSTRING(c.content FROM 1 FOR 200),
    SUBSTRING(c.content FROM 1 FOR 500),
    2, 2, c.topics
FROM kaoyan.chunks c
JOIN kaoyan.sources s ON c.source_id = s.id
ON CONFLICT (source_table, source_id) DO NOTHING;

-- 从 cctalk_chunks 表批量导入
INSERT INTO kaoyan.knowledge_points 
    (source_table, source_id, subject_code, subdomain_code, period_code, ktype_code, title, content_preview, difficulty, importance, tags)
SELECT
    'cctalk_chunks',
    cc.id,
    CASE cc.category
        WHEN '大牛课' THEN 'LEC'
        WHEN '100词' THEN 'LEC'
        WHEN '外国文学史' THEN 'FOR'
        WHEN '古代文学史' THEN 'ANC'
        ELSE 'LEC'
    END,
    CASE cc.category
        WHEN '大牛课' THEN 'LEC-01'
        WHEN '100词' THEN 'LEC-02'
        ELSE 'LEC-03'
    END,
    NULL,
    CASE cc.category WHEN '100词' THEN 'CONCEPT' ELSE 'NOTE' END,
    cc.title,
    SUBSTRING(cc.content FROM 1 FOR 500),
    CASE cc.category WHEN '100词' THEN 1 WHEN '大牛课' THEN 3 ELSE 2 END,
    CASE cc.category WHEN '100词' THEN 0 WHEN '大牛课' THEN 1 ELSE 2 END,
    cc.topics
FROM kaoyan.cctalk_chunks cc
ON CONFLICT (source_table, source_id) DO NOTHING;

-- 从 exam_questions 表批量导入
INSERT INTO kaoyan.knowledge_points 
    (source_table, source_id, subject_code, subdomain_code, period_code, ktype_code, title, content_preview, difficulty, importance, tags)
SELECT
    'exam_questions',
    eq.id,
    'EXAM', NULL, NULL, 'EXAM',
    SUBSTRING(eq.question_text FROM 1 FOR 200),
    eq.question_text,
    CASE eq.question_type
        WHEN '名词解释' THEN 1
        WHEN '简答题' THEN 2
        WHEN '论述题' THEN 4
        WHEN '评论题' THEN 4
        WHEN '作文题' THEN 5
        ELSE 2
    END,
    0,
    ARRAY[eq.question_type, eq.subject_direction]
FROM kaoyan.exam_questions eq
ON CONFLICT (source_table, source_id) DO NOTHING;
*/

-- ============================================================
-- 9. 常用查询示例
-- ============================================================

-- 查看总体覆盖率
-- SELECT * FROM kaoyan.v_coverage_summary;

-- 查看未覆盖的核心知识点（前20个）
-- SELECT * FROM kaoyan.v_uncovered_points LIMIT 20;

-- 查看第5章的覆盖情况
-- SELECT * FROM kaoyan.get_chapter_coverage(5);

-- 查看古代文学未覆盖的核心知识点
-- SELECT * FROM kaoyan.get_uncovered_core('ANC');

-- 按融入方式统计质量
-- SELECT * FROM kaoyan.v_integration_methods;

-- 查看各章节知识点分布
-- SELECT * FROM kaoyan.v_chapter_coverage;

-- ============================================================
-- 完成
-- ============================================================
