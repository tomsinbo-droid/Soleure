'use strict';

// Một file dữ liệu mẫu duy nhất. Không chứa mật khẩu hay khóa Firebase.
// Không tạo bill đã thanh toán, hoa hồng hay bảng lương giả.
const seedSource = 'soleure-intern-seed-v1';

const users = [
  {uid: 'soleure_seed_admin_v1', displayName: 'Admin Soléure (Demo)', email: 'soleure.demo.admin@example.com', phone: '0000000001', role: 'admin', hourlyRate: 0, active: true},
  {uid: 'soleure_seed_manager_v1', displayName: 'Quản lý Soléure (Demo)', email: 'soleure.demo.manager@example.com', phone: '0000000002', role: 'manager', hourlyRate: 40000, active: true},
  {uid: 'soleure_seed_staff_v1', displayName: 'Nhân viên Soléure (Demo)', email: 'soleure.demo.staff@example.com', phone: '0000000003', role: 'staff', hourlyRate: 30000, active: true},
  {uid: 'soleure_seed_staff2_v1', displayName: 'Nhân viên thay ca (Demo)', email: 'soleure.demo.staff2@example.com', phone: '0000000004', role: 'staff', hourlyRate: 32000, active: true},
];

const products = [
  {sku: 'MGT-00125', name: 'LBWK Nissan GT-R R35', brand: 'Mini GT', series: 'LBWK', price: 520000, cost: 360000, stock: 3, location: 'T01 / A02', promoPercent: 0, kpiEligible: true},
  {sku: 'KH-00218', name: 'Honda NSX Kaido Works', brand: 'Kaido House', series: 'JDM', price: 690000, cost: 470000, stock: 5, location: 'T02 / B01', promoPercent: 0, kpiEligible: true},
  {sku: 'INNO-00331', name: 'Nissan Skyline R34', brand: 'Inno64', series: 'Racing', price: 480000, cost: 330000, stock: 2, location: 'T01 / C03', promoPercent: 0, kpiEligible: true},
  {sku: 'PGM-00107', name: 'Porsche 911 RWB', brand: 'PGM', series: 'Premium', price: 1180000, cost: 880000, stock: 1, location: 'T03 / A01', promoPercent: 0, kpiEligible: true},
  {sku: 'TW-00088', name: 'Lamborghini Aventador', brand: 'Tarmac Works', series: 'Global64', price: 420000, cost: 290000, stock: 7, location: 'T02 / C02', promoPercent: 0, kpiEligible: true},
  {sku: 'MGT-00190', name: 'Porsche 911 GT3 RS', brand: 'Mini GT', series: 'Porsche', price: 560000, cost: 395000, stock: 4, location: 'T01 / B04', promoPercent: 0, kpiEligible: true},
  {sku: 'INNO-00352', name: 'Toyota Supra A80', brand: 'Inno64', series: 'JDM', price: 540000, cost: 375000, stock: 4, location: 'T02 / A04', promoPercent: 0, kpiEligible: true},
  {sku: 'TW-00095', name: 'Audi R8 LMS', brand: 'Tarmac Works', series: 'Racing', price: 410000, cost: 270000, stock: 8, location: 'T02 / B03', promoPercent: 0, kpiEligible: true},
  {sku: 'KH-00245', name: 'Nissan Datsun 510', brand: 'Kaido House', series: 'JDM', price: 720000, cost: 490000, stock: 3, location: 'T03 / C01', promoPercent: 0, kpiEligible: true},
  {sku: 'MGT-00204', name: 'Mercedes-Benz 190E', brand: 'Mini GT', series: 'DTM', price: 500000, cost: 340000, stock: 6, location: 'T01 / C02', promoPercent: 0, kpiEligible: true},
];
const customers = [
  {id: 'SEED_C014', name: 'Khách mẫu A', phone: '0000000014', favorite: 'Porsche / Mini GT'},
  {id: 'SEED_C021', name: 'Khách mẫu B', phone: '0000000021', favorite: 'JDM / Kaido House'},
  {id: 'SEED_C032', name: 'Khách mẫu C', phone: '0000000032', favorite: 'Lamborghini'},
  {id: 'SEED_C040', name: 'Khách mẫu D', phone: '0000000040', favorite: 'Mini GT'},
  {id: 'SEED_C052', name: 'Khách mẫu E', phone: '0000000052', favorite: 'JDM / Inno64'},
  {id: 'SEED_C063', name: 'Khách mẫu F', phone: '0000000063', favorite: 'Audi / Tarmac Works'},
];
const suppliers = [
  {id: 'SEED_SUP_01', name: 'Nhà cung cấp mô hình A (Demo)', phone: '0000000101', email: 'soleure.supplier1@example.com', note: 'Dữ liệu mẫu Firebase DEV', active: true},
  {id: 'SEED_SUP_02', name: 'Nhà cung cấp mô hình B (Demo)', phone: '0000000102', email: 'soleure.supplier2@example.com', note: 'Dữ liệu mẫu Firebase DEV', active: true},
  {id: 'SEED_SUP_03', name: 'Nhà cung cấp mô hình C (Demo)', phone: '0000000103', email: 'soleure.supplier3@example.com', note: 'Dữ liệu mẫu Firebase DEV', active: true},
];
const settings = {commissionRate: 0.05, holdMinutes: 30, hourlyRateDefault: 28000, maxWeeklyHours: 48};

module.exports = {seedSource, users, products, customers, suppliers, settings};
