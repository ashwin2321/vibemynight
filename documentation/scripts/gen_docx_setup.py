import os
from docx import Document
from docx.shared import Inches, Pt, RGBColor
from docx.enum.text import WD_ALIGN_PARAGRAPH
from docx.enum.table import WD_TABLE_ALIGNMENT
from docx.oxml import OxmlElement, parse_xml
from docx.oxml.ns import nsdecls, qn

OUT_DIR = r"C:\Users\ADMIN\Downloads\vibemynight-phase1-10\documentation"
os.makedirs(OUT_DIR, exist_ok=True)

def set_cell_background(cell, fill_hex):
    tcPr = cell._element.get_or_add_tcPr()
    shd = parse_xml(f'<w:shd {nsdecls("w")} w:fill="{fill_hex}"/>')
    tcPr.append(shd)

def set_cell_margins(cell, top=100, bottom=100, left=150, right=150):
    tcPr = cell._element.get_or_add_tcPr()
    tcMar = OxmlElement('w:tcMar')
    for m, val in [('top', top), ('bottom', bottom), ('left', left), ('right', right)]:
        node = OxmlElement(f'w:{m}')
        node.set(qn('w:w'), str(val))
        node.set(qn('w:type'), 'dxa')
        tcMar.append(node)
    tcPr.append(tcMar)

def add_styled_heading(doc, text, level):
    h = doc.add_heading(level=level)
    run = h.add_run(text)
    if level == 1:
        run.font.name = 'Segoe UI'
        run.font.size = Pt(16)
        run.font.bold = True
        run.font.color.rgb = RGBColor(30, 58, 138)
        h.paragraph_format.space_before = Pt(14)
        h.paragraph_format.space_after = Pt(6)
    elif level == 2:
        run.font.name = 'Segoe UI'
        run.font.size = Pt(13)
        run.font.bold = True
        run.font.color.rgb = RGBColor(131, 24, 67)
        h.paragraph_format.space_before = Pt(10)
        h.paragraph_format.space_after = Pt(4)
    elif level == 3:
        run.font.name = 'Segoe UI'
        run.font.size = Pt(11)
        run.font.bold = True
        run.font.color.rgb = RGBColor(55, 65, 81)
        h.paragraph_format.space_before = Pt(8)
        h.paragraph_format.space_after = Pt(2)
    return h

def add_code_block(doc, text):
    tbl = doc.add_table(rows=1, cols=1)
    tbl.alignment = WD_TABLE_ALIGNMENT.CENTER
    cell = tbl.cell(0, 0)
    set_cell_background(cell, "0F172A")
    set_cell_margins(cell, top=120, bottom=120, left=160, right=160)
    p = cell.paragraphs[0]
    p.paragraph_format.space_before = Pt(2)
    p.paragraph_format.space_after = Pt(2)
    r = p.add_run(text)
    r.font.name = "Consolas"
    r.font.size = Pt(8.5)
    r.font.color.rgb = RGBColor(241, 245, 249)
    doc.add_paragraph().paragraph_format.space_after = Pt(4)

def add_callout(doc, text, title="IMPORTANT"):
    tbl = doc.add_table(rows=1, cols=1)
    tbl.alignment = WD_TABLE_ALIGNMENT.CENTER
    cell = tbl.cell(0, 0)
    set_cell_background(cell, "F3F4F6")
    set_cell_margins(cell, top=140, bottom=140, left=200, right=200)
    tcPr = cell._element.get_or_add_tcPr()
    borders = parse_xml(f'''
        <w:tcBorders {nsdecls("w")}>
            <w:top w:val="none"/>
            <w:left w:val="single" w:sz="24" w:space="0" w:color="3B82F6"/>
            <w:bottom w:val="none"/>
            <w:right w:val="none"/>
        </w:tcBorders>
    ''')
    tcPr.append(borders)
    p = cell.paragraphs[0]
    p.paragraph_format.space_before = Pt(2)
    p.paragraph_format.space_after = Pt(2)
    r_title = p.add_run(f"[{title}] ")
    r_title.bold = True
    r_title.font.name = "Segoe UI"
    r_title.font.size = Pt(9.5)
    r_title.font.color.rgb = RGBColor(30, 58, 138)
    r_text = p.add_run(text)
    r_text.font.name = "Segoe UI"
    r_text.font.size = Pt(9.5)
    r_text.font.color.rgb = RGBColor(31, 41, 55)
    doc.add_paragraph().paragraph_format.space_after = Pt(4)

def add_table_data(doc, headers, data, col_widths=None):
    tbl = doc.add_table(rows=len(data) + 1, cols=len(headers))
    tbl.alignment = WD_TABLE_ALIGNMENT.CENTER
    tbl.autofit = False
    hdr_row = tbl.rows[0]
    for idx, h in enumerate(headers):
        cell = hdr_row.cells[idx]
        set_cell_background(cell, "1E3A8A")
        set_cell_margins(cell, top=100, bottom=100, left=120, right=120)
        p = cell.paragraphs[0]
        p.alignment = WD_ALIGN_PARAGRAPH.CENTER
        p.paragraph_format.space_before = Pt(2)
        p.paragraph_format.space_after = Pt(2)
        r = p.add_run(h)
        r.font.name = "Segoe UI"
        r.font.size = Pt(9.5)
        r.font.bold = True
        r.font.color.rgb = RGBColor(255, 255, 255)
        if col_widths and idx < len(col_widths):
            cell.width = col_widths[idx]
            
    for r_idx, row_data in enumerate(data):
        row = tbl.rows[r_idx + 1]
        bg = "F9FAFB" if r_idx % 2 == 0 else "FFFFFF"
        for c_idx, val in enumerate(row_data):
            cell = row.cells[c_idx]
            set_cell_background(cell, bg)
            set_cell_margins(cell, top=80, bottom=80, left=120, right=120)
            p = cell.paragraphs[0]
            p.alignment = WD_ALIGN_PARAGRAPH.CENTER if c_idx == 0 else WD_ALIGN_PARAGRAPH.LEFT
            p.paragraph_format.space_before = Pt(2)
            p.paragraph_format.space_after = Pt(2)
            r = p.add_run(str(val))
            r.font.name = "Segoe UI"
            r.font.size = Pt(9)
            r.font.color.rgb = RGBColor(17, 24, 39)
            if col_widths and c_idx < len(col_widths):
                cell.width = col_widths[c_idx]
    doc.add_paragraph().paragraph_format.space_after = Pt(6)

# BUILD SETUP DOCUMENT
doc = Document()

# Cover
title_p = doc.add_paragraph()
title_p.alignment = WD_ALIGN_PARAGRAPH.CENTER
title_p.paragraph_format.space_before = Pt(36)
title_p.paragraph_format.space_after = Pt(6)
r_title = title_p.add_run("DEPLOYMENT & ENVIRONMENT SETUP GUIDE")
r_title.font.name = "Segoe UI"
r_title.font.size = Pt(22)
r_title.font.bold = True
r_title.font.color.rgb = RGBColor(30, 58, 138)

sub_p = doc.add_paragraph()
sub_p.alignment = WD_ALIGN_PARAGRAPH.CENTER
sub_p.paragraph_format.space_after = Pt(24)
r_sub = sub_p.add_run("VibeMyNight — Local Development, MySQL Configuration & Production Cloud Deployment")
r_sub.font.name = "Segoe UI"
r_sub.font.size = Pt(13)
r_sub.font.color.rgb = RGBColor(131, 24, 67)

meta_data = [
    ["Document Version", "1.0.0"],
    ["Intended Audience", "DevOps Engineers, Full-Stack Developers, System Administrators"],
    ["Backend Stack", "Spring Boot 3.3.4, Java 21 LTS, Maven 3.9, MySQL 8.0, Docker"],
    ["Frontend Stack", "Flutter 3.27+ SDK, Node.js 24+, Vercel CLI"],
    ["Production URLs", "Frontend: https://vibemynight.vercel.app | Backend: Render Docker Web Service"]
]
add_table_data(doc, ["Deployment Property", "Details"], meta_data, [Inches(2.2), Inches(4.3)])

doc.add_page_break()

# 1. System Prerequisites
add_styled_heading(doc, "1. System Prerequisites & Environment Setup", 1)
p = doc.add_paragraph()
p.add_run("Before building and running the VibeMyNight application suite, ensure the following toolchains are installed and available on system PATH:")

prereq_data = [
    ["Component", "Minimum Version", "Purpose & Verification Command"],
    ["Java Development Kit (JDK)", "JDK 21 LTS (Temurin/Oracle)", "Spring Boot backend compilation (`java -version`)"],
    ["Apache Maven", "Maven 3.9+", "Java dependency management & packaging (`mvn -version`)"],
    ["Flutter SDK", "Flutter 3.27+", "Cross-platform client build (`flutter doctor`)"],
    ["Node.js & NPX", "Node.js 20+ / 24+ LTS", "Vercel edge deployment & tooling (`node -v; npx -v`)"],
    ["MySQL Server", "MySQL 8.0+", "Production relational database storage (`mysql --version`)"],
    ["Git Version Control", "Git 2.40+", "Repository cloning & deployment triggers (`git --version`)"]
]
add_table_data(doc, prereq_data[0], prereq_data[1:], [Inches(1.8), Inches(1.8), Inches(2.9)])

# 2. MySQL Database Setup
add_styled_heading(doc, "2. MySQL Database Initialization", 1)
p_db = doc.add_paragraph()
p_db.add_run("Execute the following SQL commands in your MySQL CLI or phpMyAdmin / MySQL Workbench:")

db_sql = """-- Create Database with UTF-8 support
CREATE DATABASE IF NOT EXISTS vibemynight 
CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- Create Dedicated User (Optional for Production)
CREATE USER IF NOT EXISTS 'vmn_user'@'localhost' IDENTIFIED BY 'VibePassword@2026';
GRANT ALL PRIVILEGES ON vibemynight.* TO 'vmn_user'@'localhost';
FLUSH PRIVILEGES;"""
add_code_block(doc, db_sql)

# 3. Backend Configuration & Startup
add_styled_heading(doc, "3. Spring Boot Backend Setup", 1)
p_prop = doc.add_paragraph()
p_prop.add_run("Configure `vibemynight/backend/spring_boot/src/main/resources/application.properties` with your database credentials and JWT secret:")

app_props = """# Server Configuration
server.port=8080
server.servlet.context-path=/api/v1

# MySQL Database Connection
spring.datasource.url=jdbc:mysql://localhost:3306/vibemynight?useSSL=false&allowPublicKeyRetrieval=true&serverTimezone=UTC
spring.datasource.username=root
spring.datasource.password=root
spring.datasource.driver-class-name=com.mysql.cj.jdbc.Driver

# JPA & Hibernate Settings
spring.jpa.hibernate.ddl-auto=update
spring.jpa.show-sql=false
spring.jpa.properties.hibernate.dialect=org.hibernate.dialect.MySQLDialect

# JWT Security Configuration
app.jwt.secret=9a4f2c8d7e1b5a3f6c8e0d2b4a6f8c1e3d5b7a9f2c4e6d8a0b2c4e6f8a0b2c4e
app.jwt.expiration-ms=86400000

# CORS Allowed Origins
app.cors.allowed-origins=http://localhost:3000,http://localhost:8080,https://vibemynight.vercel.app"""
add_code_block(doc, app_props)

add_styled_heading(doc, "3.1 Building and Running the Backend", 2)
cmd_backend = """# Step 1: Navigate to Backend Directory
cd vibemynight/backend/spring_boot

# Step 2: Clean & Package JAR (Skipping tests for fast build)
mvn clean package -DskipTests

# Step 3: Launch Spring Boot Microservice
java -jar target/vibemynight-backend-0.1.0.jar"""
add_code_block(doc, cmd_backend)

# 4. Flutter Frontend Setup
add_styled_heading(doc, "4. Flutter Frontend Setup & Build Commands", 1)
p_flt = doc.add_paragraph()
p_flt.add_run("The Flutter app supports responsive Web, Android, and iOS builds:")

cmd_flt = """# Step 1: Navigate to Frontend Directory
cd vibemynight/frontend/flutter_app

# Step 2: Install Flutter Dependencies
flutter pub get

# Step 3: Run Static Analysis & Tests
flutter analyze
flutter test

# Step 4: Run Locally on Chrome (Development)
flutter run -d chrome --web-port 3000

# Step 5: Build Production Web Bundle
flutter build web --release --base-href /

# Step 6: Build Android Release APK
flutter build apk --release"""
add_code_block(doc, cmd_flt)

# 5. Production Cloud Deployment
add_styled_heading(doc, "5. Production Cloud Deployment Guide", 1)
add_styled_heading(doc, "5.1 Frontend Deployment on Vercel (100% Free Edge CDN)", 2)
p_ver = doc.add_paragraph()
p_ver.add_run("1. Authenticate Vercel CLI: `npx vercel login`\n")
p_ver.add_run("2. Deploy release bundle: `npx vercel deploy build/web --prod --name vibemynight --yes`\n")
p_ver.add_run("3. Live Edge URL: https://vibemynight.vercel.app\n")
p_ver.add_run("4. Custom Domain: In Vercel Dashboard -> Project Settings -> Domains, enter your purchased domain (e.g. `vibemynight.com`) and point DNS CNAME to `cname.vercel-dns.com`.")

add_styled_heading(doc, "5.2 Backend Deployment on Render.com (Multi-Stage Docker)", 2)
p_ren = doc.add_paragraph()
p_ren.add_run("We provide a production multi-stage `Dockerfile` and `render.yaml` at the root of the repository:\n")
p_ren.add_run("1. Push code to GitHub: `git push origin main`\n")
p_ren.add_run("2. On Render.com, create a 'New Web Service' and connect repository `ashwin2321/vibemynight`.\n")
p_ren.add_run("3. Set Runtime: `Docker` and Plan: `Free`.\n")
p_ren.add_run("4. Click 'Deploy Web Service' — Render compiles the JAR inside Alpine Docker and assigns `https://vibemynight-backend.onrender.com`.")

# Output
file_path = os.path.join(OUT_DIR, "6_Deployment_and_Setup_Guide_VibeMyNight.docx")
doc.save(file_path)
print("SUCCESS: 6_Deployment_and_Setup_Guide_VibeMyNight.docx generated at", file_path)
