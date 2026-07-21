<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        DB::unprepared(<<<'SQL'
            CREATE OR REPLACE FUNCTION validate_package_item_integrity()
            RETURNS TRIGGER
            LANGUAGE plpgsql
            AS $$
            DECLARE
                package_type VARCHAR(20);
                package_department_id BIGINT;
                service_type VARCHAR(20);
                service_department_id BIGINT;
            BEGIN
                SELECT
                    catalog_items.type,
                    categories.department_id
                INTO
                    package_type,
                    package_department_id
                FROM catalog_items
                INNER JOIN categories
                    ON categories.id = catalog_items.category_id
                WHERE catalog_items.id = NEW.package_id
                  AND catalog_items.deleted_at IS NULL
                  AND categories.deleted_at IS NULL;

                IF package_type IS NULL THEN
                    RAISE EXCEPTION
                        'The selected package does not exist or is deleted.';
                END IF;

                IF package_type <> 'package' THEN
                    RAISE EXCEPTION
                        'package_id must reference a catalog item of type package.';
                END IF;

                SELECT
                    catalog_items.type,
                    categories.department_id
                INTO
                    service_type,
                    service_department_id
                FROM catalog_items
                INNER JOIN categories
                    ON categories.id = catalog_items.category_id
                WHERE catalog_items.id = NEW.service_id
                  AND catalog_items.deleted_at IS NULL
                  AND categories.deleted_at IS NULL;

                IF service_type IS NULL THEN
                    RAISE EXCEPTION
                        'The selected service does not exist or is deleted.';
                END IF;

                IF service_type <> 'service' THEN
                    RAISE EXCEPTION
                        'service_id must reference a catalog item of type service.';
                END IF;

                IF package_department_id <> service_department_id THEN
                    RAISE EXCEPTION
                        'A package and its services must belong to the same department.';
                END IF;

                RETURN NEW;
            END;
            $$;
        SQL);

        DB::unprepared(<<<'SQL'
            CREATE TRIGGER package_items_integrity_trigger
            BEFORE INSERT OR UPDATE
            ON package_items
            FOR EACH ROW
            EXECUTE FUNCTION validate_package_item_integrity();
        SQL);
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        DB::unprepared(
            'DROP TRIGGER IF EXISTS package_items_integrity_trigger
             ON package_items;'
        );

        DB::unprepared(
            'DROP FUNCTION IF EXISTS validate_package_item_integrity();'
        );
    }
};
