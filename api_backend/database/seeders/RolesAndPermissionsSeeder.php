<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;
use Spatie\Permission\Models\Permission;
use Spatie\Permission\Models\Role;
use Spatie\Permission\PermissionRegistrar;

class RolesAndPermissionsSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        app(PermissionRegistrar::class)->forgetCachedPermissions();

        DB::transaction(function (): void {
            $guardName = 'web';

            /*
             * Remove obsolete authenticated roles.
             *
             * Reception and employees no longer have login accounts.
             * Employees will later exist as business records managed
             * exclusively by the manager.
             */
            $obsoleteRoles = Role::query()
                ->where('guard_name', $guardName)
                ->whereIn('name', [
                    'reception_salon',
                    'reception_clinic',
                    'employee',
                ])
                ->get();

            foreach ($obsoleteRoles as $role) {
                $role->syncPermissions([]);
                $role->delete();
            }

            /*
             * Current official manager permissions.
             */
            $permissionNames = [
                'appointments.manage',
                'customers.manage',
                'services.manage',
                'employees.manage',
                'reports.view',
                'sales.view',
                'profits.view',
                'coupons.manage',
                'notifications.send_bulk',
                'reviews.view',
                'payments.manage',
                'gift_cards.manage',
                'service_images.manage',
                'settings.manage',
                'activity_logs.view',
            ];

            /*
             * Safely remove permissions that no longer belong
             * to the official project requirements.
             */
            $obsoletePermissions = Permission::query()
                ->where('guard_name', $guardName)
                ->whereNotIn('name', $permissionNames)
                ->get();

            foreach ($obsoletePermissions as $permission) {
                $permission->roles()->detach();
                $permission->delete();
            }

            /*
             * Create or keep the current permissions.
             */
            foreach ($permissionNames as $permissionName) {
                Permission::findOrCreate($permissionName, $guardName);
            }

            /*
             * Only two authenticated account types remain:
             * manager and customer.
             */
            $manager = Role::findOrCreate('manager', $guardName);
            $customer = Role::findOrCreate('customer', $guardName);

            $manager->syncPermissions(
                Permission::query()
                    ->where('guard_name', $guardName)
                    ->whereIn('name', $permissionNames)
                    ->get()
            );

            /*
             * Customer authorization will depend on authenticated
             * customer routes, ownership policies and API checks.
             */
            $customer->syncPermissions([]);
        });

        app(PermissionRegistrar::class)->forgetCachedPermissions();
    }
}