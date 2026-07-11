<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
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

        $permissions = [
            // Appointments
            'appointments.view_all',
            'appointments.view_department',
            'appointments.view_own',
            'appointments.confirm',
            'appointments.update',
            'appointments.cancel',
            'appointments.assign_employees',
            'appointments.create_manual',
            'appointments.start',
            'appointments.complete',

            // Customers
            'customers.view_all',
            'customers.view_department',
            'customers.view_related',

            // Employees
            'employees.manage',

            // Catalog and prices
            'catalog.view',
            'catalog.manage',
            'prices.update',

            // Offers, posts and banners
            'offers.manage',
            'posts.manage',
            'banners.manage',

            // Chat
            'chat.view_all',
            'chat.view_department',

            // Notifications
            'notifications.send_individual',
            'notifications.send_bulk',

            // Payments and invoices
            'payments.manage',
            'invoices.manage',

            // Reviews
            'reviews.view_all',
            'reviews.view_own',

            // Reports and profits
            'reports.view',
            'profits.view',

            // System administration
            'settings.manage',
            'roles.manage',
            'activity_logs.view',
        ];

        foreach ($permissions as $permission) {
            Permission::findOrCreate($permission, 'web');
        }

        $manager = Role::findOrCreate('manager', 'web');
        $receptionSalon = Role::findOrCreate('reception_salon', 'web');
        $receptionClinic = Role::findOrCreate('reception_clinic', 'web');
        $employee = Role::findOrCreate('employee', 'web');
        Role::findOrCreate('customer', 'web');

        $manager->syncPermissions(Permission::all());

        $receptionPermissions = [
            'appointments.view_department',
            'appointments.confirm',
            'appointments.update',
            'appointments.cancel',
            'appointments.assign_employees',
            'appointments.create_manual',
            'appointments.start',
            'appointments.complete',
            'customers.view_department',
            'catalog.view',
            'chat.view_department',
            'notifications.send_individual',
            'payments.manage',
            'invoices.manage',
        ];

        $receptionSalon->syncPermissions($receptionPermissions);
        $receptionClinic->syncPermissions($receptionPermissions);

        $employee->syncPermissions([
            'appointments.view_own',
            'appointments.start',
            'appointments.complete',
            'customers.view_related',
            'catalog.view',
            'reviews.view_own',
        ]);

        app(PermissionRegistrar::class)->forgetCachedPermissions();
    }
}