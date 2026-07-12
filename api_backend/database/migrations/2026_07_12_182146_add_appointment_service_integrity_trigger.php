<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    public function up(): void
    {
        DB::unprepared(<<<'SQL'
CREATE OR REPLACE FUNCTION validate_appointment_service()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM catalog_items
        WHERE id = NEW.service_id
          AND type = 'service'
    ) THEN
        RAISE EXCEPTION
            'Only catalog items of type service can be used in appointment_services.';
    END IF;

    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_validate_appointment_service
BEFORE INSERT OR UPDATE
ON appointment_services
FOR EACH ROW
EXECUTE FUNCTION validate_appointment_service();
SQL);
    }

    public function down(): void
    {
        DB::unprepared(<<<'SQL'
DROP TRIGGER IF EXISTS trg_validate_appointment_service
ON appointment_services;

DROP FUNCTION IF EXISTS validate_appointment_service();
SQL);
    }
};