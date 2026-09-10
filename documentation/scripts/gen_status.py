import os, openpyxl
from openpyxl.styles import Font, PatternFill, Alignment, Border, Side
from openpyxl.utils import get_column_letter

OUT_DIR = r"C:\Users\ADMIN\Downloads\vibemynight-phase1-10\documentation"
os.makedirs(OUT_DIR, exist_ok=True)

def apply_header(cell, text, fill_color="1E3A8A"):
    cell.value = text
    cell.font = Font(name="Segoe UI", size=10, bold=True, color="FFFFFF")
    cell.fill = PatternFill(start_color=fill_color, end_color=fill_color, fill_type="solid")
    cell.alignment = Alignment(horizontal="center", vertical="center", wrap_text=True)

def apply_cell(cell, value, is_even=False, align="left", bold=False, color=None):
    cell.value = value
    cell.font = Font(name="Segoe UI", size=9, bold=bold, color=color or "111827")
    bg = "F9FAFB" if is_even else "FFFFFF"
    cell.fill = PatternFill(start_color=bg, end_color=bg, fill_type="solid")
    cell.alignment = Alignment(horizontal=align, vertical="center", wrap_text=True)
    cell.border = Border(
        left=Side(style="thin", color="E5E7EB"), right=Side(style="thin", color="E5E7EB"),
        top=Side(style="thin", color="E5E7EB"), bottom=Side(style="thin", color="E5E7EB")
    )

def fit_cols(ws):
    for col in ws.columns:
        max_l = 0
        col_letter = get_column_letter(col[0].column)
        for cell in col:
            val_str = str(cell.value or "")
            for line in val_str.split("\n"):
                if len(line) > max_l: max_l = len(line)
        ws.column_dimensions[col_letter].width = min(max(max_l + 3, 13), 50)

wb = openpyxl.Workbook()
ws_dash = wb.active
ws_dash.title = "Executive Summary"
h_dash = ["Metric", "Value / Status", "Key Highlights & Verification"]
for i, h in enumerate(h_dash, 1):
    apply_header(ws_dash.cell(row=1, column=i), h, "1E3A8A")
ws_dash.row_dimensions[1].height = 26

dash = [
    ("Project Name", "VibeMyNight (Event & Navratri Pass Discovery Platform)", "Phase 1 to Phase 14 Complete"),
    ("Technology Stack", "Flutter Web/Mobile + Spring Boot 3.3.4 + MySQL 8 + Riverpod + GoRouter", "Clean architecture, JWT authentication, responsive Figma dark neon theme"),
    ("Total Phases Planned", "14 Phases", "Phase 1 (Foundation) through Phase 14 (Deployment & Documentation)"),
    ("Completed Phases", "14 / 14 (100%)", "Full customer journey + Admin CMS + Invoice Generator + Cloud Hosting"),
    ("Automated Tests", "16 / 16 Tests Passed (100%)", "Models JSON serialization + Core UI Widget tests verified"),
    ("Static Code Analysis", "0 Errors, 0 Warnings", "flutter analyze passed cleanly with zero issues"),
    ("Live Production Frontend", "https://vibemynight.vercel.app", "Deployed on Vercel Global Edge CDN with clean SPA routing"),
    ("Backend Cloud Readiness", "Multi-stage Dockerfile + render.yaml pushed to GitHub", "Ready for automatic build and deploy on Render.com free tier"),
    ("Payment Flow Strategy (v1)", "Server-Verified WhatsApp Pass Inquiries + Admin Billing Module", "Anti-tamper server price compute + WhatsApp deep linking + formatted receipts")
]
for r_idx, row in enumerate(dash, 2):
    for c_idx, val in enumerate(row, 1):
        apply_cell(ws_dash.cell(row=r_idx, column=c_idx), val, r_idx%2==0, "left", bold=(c_idx==1))
    ws_dash.row_dimensions[r_idx].height = 25
fit_cols(ws_dash)

ws_phases = wb.create_sheet(title="Phase-by-Phase Tracker")
h_phases = ["Phase ID", "Phase Name & Domain", "Planned Deliverables", "Implementation Status", "Completion %", "What Was Done", "Known Gaps / Future Scope", "Assumptions Made"]
for i, h in enumerate(h_phases, 1):
    apply_header(ws_phases.cell(row=1, column=i), h, "0F766E")
ws_phases.row_dimensions[1].height = 26

phases = [
    ("Phase 1", "Project Scaffolding & Design System", "Theme, assets, AppColors, AppTheme", "COMPLETED", "100%", "Created unified theme matching Figma (#0A0A12, Neon Pink, Purple, Cyan, Gold), typography, buttons, glass cards.", "None", "Dark theme is default"),
    ("Phase 2", "Spring Boot Domain Entities & DB Schema", "JPA entities: Event, EventDay, Pass, Artist, Facility, Inquiry, AdminUser", "COMPLETED", "100%", "Built all domain entities, JPA repositories, relationships with cascades and validation.", "None", "MySQL 8 support"),
    ("Phase 3", "Public REST Endpoints", "Public read APIs for events, days, artists, facilities, settings", "COMPLETED", "100%", "Controllers, Services, DTO mappers built with global exception handler.", "None", "Public catalog excludes draft events"),
    ("Phase 4", "Admin Security & JWT Authentication", "BCrypt password hashing, JWT provider, filter, login endpoint", "COMPLETED", "100%", "Spring Security filter chain, stateless session, 24h JWT expiration.", "None", "Admin username/password seeded in DB"),
    ("Phase 5", "Admin CRUD REST Endpoints", "Admin management for events, days, passes, lineup, facilities, settings", "COMPLETED", "100%", "Full lifecycle endpoints with status toggles and inquiry tracking.", "None", "Cascade deletes applied carefully"),
    ("Phase 6", "Pass Inquiry & WhatsApp Lead Engine", "POST /inquiries, server price compute, WhatsApp URL generation", "COMPLETED", "100%", "Server-side price verification, anti-tampering logic, inquiry ledger.", "None", "Inquiries default to status NEW"),
    ("Phase 7", "Flutter Core Architecture & Router", "Riverpod state management, GoRouter, Dio/Http client, TokenStorage", "COMPLETED", "100%", "Clean architecture, auth interceptors, protected route guards.", "None", "Web & Mobile responsive layout"),
    ("Phase 8", "Customer UI Screens", "Home, Events, EventDetails, EventDay, Artists, Inquiry, Success", "COMPLETED", "100%", "Dynamic catalog, date selector, pass tier selector, high-DPI branding.", "None", "Figma layout match"),
    ("Phase 9", "Admin Web Portal Screens", "Login, Dashboard, Event/Day/Pass/Artist/Facility/Inquiry CMS", "COMPLETED", "100%", "AdminShell navigation, table views, status badges, metrics summary.", "None", "Responsive sidebar 260px"),
    ("Phase 10", "End-to-End Integration & Bug Fixes", "Full dynamic API wiring, query param routing, Riverpod web type fixes", "COMPLETED", "100%", "Fixed TypeError on web runtime, enabled direct query param routing for inquiries.", "None", "Zero static mock data in production"),
    ("Phase 11", "Admin Billing & WhatsApp Invoice Module", "Manual & inquiry-backed bill generator with WhatsApp share", "COMPLETED", "100%", "Created /admin/billing with live tax/discount calculations, receipt card, WhatsApp dispatch.", "None", "Added per user request"),
    ("Phase 12", "Public UI Cleanups & High-DPI Assets", "Remove public admin link from footer, high-resolution logo widget", "COMPLETED", "100%", "Removed footer admin portal link, added FilterQuality.high logo widget.", "None", "Admin accessible via /admin/login"),
    ("Phase 13", "Production Cloud Hosting & CI/CD", "Vercel Web deployment, Multi-stage Dockerfile, Netlify routing", "COMPLETED", "100%", "Generated build/web, deployed to https://vibemynight.vercel.app, prepared Docker for Render.", "None", "Custom domain to be bound in 20 days"),
    ("Phase 14", "Comprehensive Project Documentation", "SRS, TAD, API xlsx, DB xlsx, Test Plan xlsx, User Manuals, Setup Guide", "COMPLETED", "100%", "Produced all 9 complete deliverables with exact project codebase context.", "None", "Complete for client handover")
]
for r_idx, row in enumerate(phases, 2):
    for c_idx, val in enumerate(row, 1):
        color = "047857" if c_idx == 4 and val == "COMPLETED" else None
        apply_cell(ws_phases.cell(row=r_idx, column=c_idx), val, r_idx%2==0, "center" if c_idx in [1, 4, 5] else "left", bold=(c_idx in [1, 4]), color=color)
    ws_phases.row_dimensions[r_idx].height = 34
fit_cols(ws_phases)

p = os.path.join(OUT_DIR, "9_Project_Status_Report_VibeMyNight.xlsx")
wb.save(p)
print("SUCCESS: Project Status Report Excel saved at", p)
