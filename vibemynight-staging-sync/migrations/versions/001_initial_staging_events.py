"""initial staging events table

Revision ID: 001_initial_staging_events
Revises: 
Create Date: 2026-10-02 10:30:00.000000

"""
from alembic import op
import sqlalchemy as sa

revision = '001_initial_staging_events'
down_revision = None
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.create_table(
        'staging_events',
        sa.Column('id', sa.Integer(), autoincrement=True, nullable=False),
        sa.Column('source', sa.String(length=50), nullable=False, server_default='showmates'),
        sa.Column('source_event_id', sa.String(length=100), nullable=False),
        sa.Column('source_url', sa.String(length=500), nullable=True),
        sa.Column('title', sa.String(length=255), nullable=False),
        sa.Column('description', sa.Text(), nullable=True),
        sa.Column('enhanced_title', sa.String(length=255), nullable=True),
        sa.Column('catchy_description', sa.Text(), nullable=True),
        sa.Column('highlights', sa.JSON(), nullable=True),
        sa.Column('genre_tags', sa.JSON(), nullable=True),
        sa.Column('seo_keywords', sa.JSON(), nullable=True),
        sa.Column('whatsapp_teaser', sa.String(length=500), nullable=True),
        sa.Column('poster_url', sa.String(length=500), nullable=True),
        sa.Column('banner_url', sa.String(length=500), nullable=True),
        sa.Column('event_start_date', sa.String(length=50), nullable=True),
        sa.Column('event_end_date', sa.String(length=50), nullable=True),
        sa.Column('start_time', sa.String(length=20), nullable=True),
        sa.Column('end_time', sa.String(length=20), nullable=True),
        sa.Column('venue_name', sa.String(length=255), nullable=True),
        sa.Column('venue_address', sa.Text(), nullable=True),
        sa.Column('city', sa.String(length=100), nullable=True),
        sa.Column('state', sa.String(length=100), nullable=True),
        sa.Column('min_ticket_price', sa.Float(), nullable=True),
        sa.Column('max_ticket_price', sa.Float(), nullable=True),
        sa.Column('currency', sa.String(length=10), nullable=False, server_default='INR'),
        sa.Column('raw_payload', sa.JSON(), nullable=True),
        sa.Column('status', sa.String(length=50), nullable=False, server_default='PENDING_REVIEW'),
        sa.Column('duplicate_of', sa.Integer(), nullable=True),
        sa.Column('ai_processed', sa.Boolean(), nullable=False, server_default=sa.text('false')),
        sa.Column('ai_provider', sa.String(length=50), nullable=True),
        sa.Column('ai_model', sa.String(length=50), nullable=True),
        sa.Column('ai_error', sa.Text(), nullable=True),
        sa.Column('created_at', sa.DateTime(), nullable=False, server_default=sa.func.now()),
        sa.Column('updated_at', sa.DateTime(), nullable=False, server_default=sa.func.now()),
        sa.PrimaryKeyConstraint('id')
    )
    op.create_index('idx_source_source_id', 'staging_events', ['source', 'source_event_id'])
    op.create_index('idx_title_city_date', 'staging_events', ['title', 'city', 'event_start_date'])
    op.create_index(op.f('ix_staging_events_id'), 'staging_events', ['id'], unique=False)
    op.create_index(op.f('ix_staging_events_status'), 'staging_events', ['status'], unique=False)
    op.create_index(op.f('ix_staging_events_city'), 'staging_events', ['city'], unique=False)


def downgrade() -> None:
    op.drop_index(op.f('ix_staging_events_city'), table_name='staging_events')
    op.drop_index(op.f('ix_staging_events_status'), table_name='staging_events')
    op.drop_index(op.f('ix_staging_events_id'), table_name='staging_events')
    op.drop_index('idx_title_city_date', table_name='staging_events')
    op.drop_index('idx_source_source_id', table_name='staging_events')
    op.drop_table('staging_events')
