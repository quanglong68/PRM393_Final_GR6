// ignore_for_file: avoid_print

import 'dart:io';
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

void main() async {
  final regularBytes = File('assets/fonts/DejaVuSans.ttf').readAsBytesSync();
  final boldBytes = File('assets/fonts/DejaVuSans-Bold.ttf').readAsBytesSync();

  final fontRegular = pw.Font.ttf(ByteData.view(regularBytes.buffer));
  final fontBold = pw.Font.ttf(ByteData.view(boldBytes.buffer));

  final doc = pw.Document(
    title: 'PRM393 Lab 3 — Project Report [CHỜ ĐIỀN STUDENT ID]',
    author: 'Student ID: [CHỜ ĐIỀN STUDENT ID]',
    subject: 'PRM393 Cloud-Enabled Mobile App Final Report',
    keywords: 'PRM393, Lab 3, Flutter, Firebase, Report, [CHỜ ĐIỀN STUDENT ID]',
  );

  pw.Widget buildHeader(String sectionTitle, int pageNum, int totalPages) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 8),
      margin: const pw.EdgeInsets.only(bottom: 12),
      decoration: const pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: PdfColors.blue800, width: 1)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text('FPTU Second Brain — PRM393 Lab 3 Report',
              style: pw.TextStyle(font: fontRegular, fontSize: 8, color: PdfColors.grey700)),
          pw.Text(sectionTitle,
              style: pw.TextStyle(font: fontBold, fontSize: 8, color: PdfColors.blue900)),
        ],
      ),
    );
  }

  pw.Widget buildFooter(int pageNum, int totalPages) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(top: 8),
      margin: const pw.EdgeInsets.only(top: 12),
      decoration: const pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(color: PdfColors.grey300, width: 0.5)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text('Student ID: [CHỜ ĐIỀN STUDENT ID] | Repository: PRM393_Lab03_[StudentID]',
              style: pw.TextStyle(font: fontRegular, fontSize: 7, color: PdfColors.grey600)),
          pw.Text('Trang $pageNum / $totalPages',
              style: pw.TextStyle(font: fontBold, fontSize: 8, color: PdfColors.blue900)),
        ],
      ),
    );
  }

  pw.Page createPage({
    required int pageNum,
    required int totalPages,
    required String sectionTitle,
    required List<pw.Widget> content,
    bool isCover = false,
  }) {
    return pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.symmetric(horizontal: 36, vertical: 32),
      build: (pw.Context context) {
        if (isCover) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: content,
          );
        }
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            buildHeader(sectionTitle, pageNum, totalPages),
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: content,
              ),
            ),
            buildFooter(pageNum, totalPages),
          ],
        );
      },
    );
  }

  final totalPages = 10;

  // ----------------------------------------------------
  // TRANG 1: BÌA BÁO CÁO & MỤC LỤC
  // ----------------------------------------------------
  doc.addPage(createPage(
    pageNum: 1,
    totalPages: totalPages,
    sectionTitle: 'Trang bìa',
    isCover: true,
    content: [
      pw.Container(
        padding: const pw.EdgeInsets.all(16),
        decoration: const pw.BoxDecoration(
          color: PdfColors.blue900,
          borderRadius: pw.BorderRadius.all(pw.Radius.circular(6)),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('TRƯỜNG ĐẠI HỌC FPT — HỌC KỲ FALL 2024 / SPRING 2025',
                style: pw.TextStyle(font: fontBold, fontSize: 10, color: PdfColors.blue100)),
            pw.SizedBox(height: 6),
            pw.Text('PRM393: MOBILE PROGRAMMING — LAB 3 REPORT',
                style: pw.TextStyle(font: fontBold, fontSize: 18, color: PdfColors.white)),
            pw.SizedBox(height: 4),
            pw.Text('FPTU Second Brain: Cloud-Enabled Academic Assistant App with Firebase & ARTEMIS E2E',
                style: pw.TextStyle(font: fontRegular, fontSize: 11, color: PdfColors.grey200)),
          ],
        ),
      ),
      pw.SizedBox(height: 20),
      pw.Container(
        padding: const pw.EdgeInsets.all(12),
        decoration: pw.BoxDecoration(
          border: pw.TableBorder.all(color: PdfColors.grey300, width: 1),
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
        ),
        child: pw.Column(
          children: [
            pw.Row(children: [
              pw.SizedBox(width: 140, child: pw.Text('Họ và tên sinh viên:', style: pw.TextStyle(font: fontBold, fontSize: 9))),
              pw.Text('Nguyễn Bá Thái Dương (và nhóm tác giả)', style: pw.TextStyle(font: fontRegular, fontSize: 9)),
            ]),
            pw.SizedBox(height: 4),
            pw.Row(children: [
              pw.SizedBox(width: 140, child: pw.Text('Student ID (Mã SV):', style: pw.TextStyle(font: fontBold, fontSize: 9, color: PdfColors.red800))),
              pw.Text('[CHỜ ĐIỀN STUDENT ID] (Ví dụ: SE123456)', style: pw.TextStyle(font: fontBold, fontSize: 9, color: PdfColors.red800)),
            ]),
            pw.SizedBox(height: 4),
            pw.Row(children: [
              pw.SizedBox(width: 140, child: pw.Text('Tên Repository nộp:', style: pw.TextStyle(font: fontBold, fontSize: 9))),
              pw.Text('PRM393_Lab03_[StudentID] (Hiện tại: prm323-lab2-gr6)', style: pw.TextStyle(font: fontRegular, fontSize: 9)),
            ]),
            pw.SizedBox(height: 4),
            pw.Row(children: [
              pw.SizedBox(width: 140, child: pw.Text('Firebase Project ID:', style: pw.TextStyle(font: fontBold, fontSize: 9))),
              pw.Text('prm323-lab2-gr6 (Google Cloud / Firebase Spark Plan)', style: pw.TextStyle(font: fontRegular, fontSize: 9)),
            ]),
            pw.SizedBox(height: 4),
            pw.Row(children: [
              pw.SizedBox(width: 140, child: pw.Text('Android Package Name:', style: pw.TextStyle(font: fontBold, fontSize: 9))),
              pw.Text('com.example.prm323_lab3', style: pw.TextStyle(font: fontRegular, fontSize: 9)),
            ]),
            pw.SizedBox(height: 4),
            pw.Row(children: [
              pw.SizedBox(width: 140, child: pw.Text('Ngày lập báo cáo:', style: pw.TextStyle(font: fontBold, fontSize: 9))),
              pw.Text('04/11/2026', style: pw.TextStyle(font: fontRegular, fontSize: 9)),
            ]),
          ],
        ),
      ),
      pw.SizedBox(height: 20),
      pw.Text('MỤC LỤC BÁO CÁO', style: pw.TextStyle(font: fontBold, fontSize: 11, color: PdfColors.blue900)),
      pw.SizedBox(height: 8),
      pw.Container(
        padding: const pw.EdgeInsets.all(10),
        decoration: const pw.BoxDecoration(color: PdfColors.grey100),
        child: pw.Column(
          children: [
            pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
              pw.Text('§1. Context & Scope — Chuyển đổi từ Lab 2 sang Lab 3', style: pw.TextStyle(font: fontRegular, fontSize: 9)),
              pw.Text('Trang 2', style: pw.TextStyle(font: fontBold, fontSize: 9)),
            ]),
            pw.SizedBox(height: 4),
            pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
              pw.Text('§2. Architecture & Design System — MVVM, Tokens & Fail-Loud', style: pw.TextStyle(font: fontRegular, fontSize: 9)),
              pw.Text('Trang 3', style: pw.TextStyle(font: fontBold, fontSize: 9)),
            ]),
            pw.SizedBox(height: 4),
            pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
              pw.Text('§3. Features & User Flows — 11 Màn hình, 3 Luồng & PDF Export', style: pw.TextStyle(font: fontRegular, fontSize: 9)),
              pw.Text('Trang 4', style: pw.TextStyle(font: fontBold, fontSize: 9)),
            ]),
            pw.SizedBox(height: 4),
            pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
              pw.Text('§4. Firebase Integration — Auth, Firestore & Storage Security', style: pw.TextStyle(font: fontRegular, fontSize: 9)),
              pw.Text('Trang 5', style: pw.TextStyle(font: fontBold, fontSize: 9)),
            ]),
            pw.SizedBox(height: 4),
            pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
              pw.Text('§5. Firebase Services — Analytics, Crashlytics, Remote Config & FCM', style: pw.TextStyle(font: fontRegular, fontSize: 9)),
              pw.Text('Trang 6', style: pw.TextStyle(font: fontBold, fontSize: 9)),
            ]),
            pw.SizedBox(height: 4),
            pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
              pw.Text('§6. Testing Strategy — Hermetic Unit/Widget Tests (89/89 Pass)', style: pw.TextStyle(font: fontRegular, fontSize: 9)),
              pw.Text('Trang 7', style: pw.TextStyle(font: fontBold, fontSize: 9)),
            ]),
            pw.SizedBox(height: 4),
            pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
              pw.Text('§7. ARTEMIS E2E Testing — Harness 26 Cases & Quota Analysis', style: pw.TextStyle(font: fontRegular, fontSize: 9)),
              pw.Text('Trang 8', style: pw.TextStyle(font: fontBold, fontSize: 9)),
            ]),
            pw.SizedBox(height: 4),
            pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
              pw.Text('§8. AI Code Review & Transparent AI Assistance Policy', style: pw.TextStyle(font: fontRegular, fontSize: 9)),
              pw.Text('Trang 9', style: pw.TextStyle(font: fontBold, fontSize: 9)),
            ]),
            pw.SizedBox(height: 4),
            pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
              pw.Text('§9. Challenges, Lessons Learned & Evidence Traceability', style: pw.TextStyle(font: fontRegular, fontSize: 9)),
              pw.Text('Trang 10', style: pw.TextStyle(font: fontBold, fontSize: 9)),
            ]),
          ],
        ),
      ),
      pw.Spacer(),
      pw.Container(
        padding: const pw.EdgeInsets.all(8),
        decoration: pw.BoxDecoration(
          color: PdfColors.yellow100,
          border: pw.Border.all(color: PdfColors.amber800, width: 0.5),
        ),
        child: pw.Text(
          'LƯU Ý LIÊM CHÍNH HỌC THUẬT: Báo cáo phân định nghiêm ngặt giữa kiểm thử tự động nội bộ (89 tests pass) '
          'và kiểm thử môi trường thực tế (device runtime / Firebase Console). Các ô chờ bằng chứng runtime được đánh dấu [⏳ CHỜ ẢNH RUNTIME].',
          style: pw.TextStyle(font: fontRegular, fontSize: 7, color: PdfColors.brown900),
        ),
      ),
    ],
  ));

  // ----------------------------------------------------
  // TRANG 2: §1 CONTEXT & SCOPE
  // ----------------------------------------------------
  doc.addPage(createPage(
    pageNum: 2,
    totalPages: totalPages,
    sectionTitle: '§1. Context & Scope',
    content: [
      pw.Text('1.1. Bối cảnh dự án & Tiến trình từ Lab 2 sang Lab 3',
          style: pw.TextStyle(font: fontBold, fontSize: 11, color: PdfColors.blue900)),
      pw.SizedBox(height: 6),
      pw.Text(
        'FPTU Second Brain được phát triển nhằm giải quyết nhu cầu quản lý học tập cá nhân hóa cho sinh viên Đại học FPT. '
        'Tại Lab 2, ứng dụng đã hoàn thành bản mẫu thiết kế giao diện (Figma Prototype), xác lập 3 personas, thiết kế các màn hình tĩnh '
        'và điều hướng cục bộ với dữ liệu mẫu (mock data).',
        style: pw.TextStyle(font: fontRegular, fontSize: 8.5),
      ),
      pw.SizedBox(height: 4),
      pw.Text(
        'Tại Lab 3, ứng dụng chuyển đổi toàn diện thành một Cloud-Enabled Mobile App thực thụ: thay thế hoàn toàn mock data bằng '
        'Cloud Firestore, xác thực tài khoản Google với ràng buộc tên miền sinh viên @fpt.edu.vn, đồng bộ tài liệu và đính kèm qua Cloud Storage, '
        'tích hợp trung tâm thông báo Firebase Cloud Messaging (FCM), giám sát vận hành với Firebase Analytics, Crashlytics và Remote Config, '
        'đồng thời kiểm thử tự động bằng Google ARTEMIS E2E framework.',
        style: pw.TextStyle(font: fontRegular, fontSize: 8.5),
      ),
      pw.SizedBox(height: 10),
      pw.Text('1.2. Chân dung người dùng mục tiêu (3 Personas)',
          style: pw.TextStyle(font: fontBold, fontSize: 10, color: PdfColors.blue800)),
      pw.SizedBox(height: 4),
      pw.Table(
        border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
        children: [
          pw.TableRow(
            decoration: const pw.BoxDecoration(color: PdfColors.blue50),
            children: [
              pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('Persona', style: pw.TextStyle(font: fontBold, fontSize: 8))),
              pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('Vai trò & Đối tượng', style: pw.TextStyle(font: fontBold, fontSize: 8))),
              pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('Nỗi đau (Pain Points)', style: pw.TextStyle(font: fontBold, fontSize: 8))),
              pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('Tính năng cốt lõi giải quyết', style: pw.TextStyle(font: fontBold, fontSize: 8))),
            ],
          ),
          pw.TableRow(children: [
            pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('P01: An', style: pw.TextStyle(font: fontBold, fontSize: 8))),
            pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('Sinh viên năm 1 (K19)\nMới vào chuyên ngành', style: pw.TextStyle(font: fontRegular, fontSize: 7.5))),
            pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('Chưa rõ lộ trình môn tiên quyết, dễ trượt slot điểm danh', style: pw.TextStyle(font: fontRegular, fontSize: 7.5))),
            pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('Tra cứu lộ trình Curriculum, kiểm tra điều kiện tiên quyết (PRO192->CSD201)', style: pw.TextStyle(font: fontRegular, fontSize: 7.5))),
          ]),
          pw.TableRow(children: [
            pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('P02: Bình', style: pw.TextStyle(font: fontBold, fontSize: 8))),
            pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('Sinh viên năm 3 (K17)\nLàm đồ án SWP391 & Lab', style: pw.TextStyle(font: fontRegular, fontSize: 7.5))),
            pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('Quá tải deadline sprint, thất lạc ghi chú code và tài liệu lab', style: pw.TextStyle(font: fontRegular, fontSize: 7.5))),
            pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('Quản lý Task theo môn, Notes Vault đồng bộ Cloud Storage, xuất Study Report PDF', style: pw.TextStyle(font: fontRegular, fontSize: 7.5))),
          ]),
          pw.TableRow(children: [
            pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('P03: Chi', style: pw.TextStyle(font: fontBold, fontSize: 8))),
            pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('Sinh viên năm cuối (K16)\nChuẩn bị OJT / Capstone', style: pw.TextStyle(font: fontRegular, fontSize: 7.5))),
            pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('Cần tối ưu GPA tốt nghiệp, phân vân học cải thiện hay học vượt', style: pw.TextStyle(font: fontRegular, fontSize: 7.5))),
            pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('Cố vấn học tập 4 cấp (Course/Semester/Program/Score) & Mô phỏng GPA kỳ 5', style: pw.TextStyle(font: fontRegular, fontSize: 7.5))),
          ]),
        ],
      ),
      pw.SizedBox(height: 10),
      pw.Text('1.3. Phạm vi triển khai Lab 3 so với Rubric chuẩn',
          style: pw.TextStyle(font: fontBold, fontSize: 10, color: PdfColors.blue800)),
      pw.SizedBox(height: 4),
      pw.Bullet(text: 'Màn hình ứng dụng: Đầy đủ 11 màn hình (8 màn hình Lab 2 + SignIn + CourseDetail + Profile/Settings/Demo Area).', style: pw.TextStyle(font: fontRegular, fontSize: 8)),
      pw.Bullet(text: 'Dịch vụ Firebase: Tích hợp trọn bộ 6 dịch vụ (Auth, Firestore, Storage, Analytics, Crashlytics, Remote Config, FCM).', style: pw.TextStyle(font: fontRegular, fontSize: 8)),
      pw.Bullet(text: 'Xử lý lỗi: Kiến trúc Fail-Loud — loại bỏ hoàn toàn mock fallback im lặng; hiển thị Error state và cho phép Retry.', style: pw.TextStyle(font: fontRegular, fontSize: 8)),
      pw.Bullet(text: 'Khả năng tiếp cận (Accessibility): Áp dụng Semantics cho toàn bộ button, input, card, banner thông báo.', style: pw.TextStyle(font: fontRegular, fontSize: 8)),
    ],
  ));

  // ----------------------------------------------------
  // TRANG 3: §2 ARCHITECTURE & DESIGN SYSTEM
  // ----------------------------------------------------
  doc.addPage(createPage(
    pageNum: 3,
    totalPages: totalPages,
    sectionTitle: '§2. Architecture & Design System',
    content: [
      pw.Text('2.1. Kiến trúc MVVM 4 tầng (Model - View - ViewModel - Service)',
          style: pw.TextStyle(font: fontBold, fontSize: 11, color: PdfColors.blue900)),
      pw.SizedBox(height: 6),
      pw.Text(
        'Dự án tuân thủ nghiêm ngặt nguyên tắc phân tách trách nhiệm (Separation of Concerns). '
        'Không có bất kỳ lệnh gọi Firebase SDK trực tiếp nào bên trong các widget giao diện (lib/screens/ và lib/widgets/).',
        style: pw.TextStyle(font: fontRegular, fontSize: 8.5),
      ),
      pw.SizedBox(height: 6),
      pw.Container(
        padding: const pw.EdgeInsets.all(8),
        decoration: pw.BoxDecoration(color: PdfColors.grey100, border: pw.Border.all(color: PdfColors.grey300, width: 0.5)),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('SƠ ĐỒ PHÂN TẦNG VÀ LUỒNG PHỤ THUỘC (DEPENDENCY INJECTION):', style: pw.TextStyle(font: fontBold, fontSize: 8, color: PdfColors.blue900)),
            pw.SizedBox(height: 4),
            pw.Text('[VIEW / SCREENS] (11 screens: HomeScreen, TasksScreen, NotesScreen, AdvisorScreen...)', style: pw.TextStyle(font: fontRegular, fontSize: 8)),
            pw.Text('      │  lắng nghe trạng thái qua context.watch<T>() / context.read<T>()', style: pw.TextStyle(font: fontRegular, fontSize: 7.5, color: PdfColors.grey700)),
            pw.Text('      ▼', style: pw.TextStyle(font: fontBold, fontSize: 8)),
            pw.Text('[VIEWMODEL] (AuthViewModel, TasksViewModel, NotesViewModel, RoadmapViewModel, AdvisorViewModel)', style: pw.TextStyle(font: fontRegular, fontSize: 8)),
            pw.Text('      │  quản lý state AsyncViewState<T>, thực thi business logic, kế thừa BaseViewModel', style: pw.TextStyle(font: fontRegular, fontSize: 7.5, color: PdfColors.grey700)),
            pw.Text('      ▼', style: pw.TextStyle(font: fontBold, fontSize: 8)),
            pw.Text('[SERVICE / REPOSITORY] (AuthService, FirestoreService, StorageService, RemoteConfigService...)', style: pw.TextStyle(font: fontRegular, fontSize: 8)),
            pw.Text('      │  giao tiếp Firebase SDK thật hoặc Test Fakes; định hình contract trừu tượng', style: pw.TextStyle(font: fontRegular, fontSize: 7.5, color: PdfColors.grey700)),
            pw.Text('      ▼', style: pw.TextStyle(font: fontBold, fontSize: 8)),
            pw.Text('[FIREBASE SDK / BACKEND] (FirebaseAuth, Cloud Firestore, Cloud Storage, FirebaseRemoteConfig)', style: pw.TextStyle(font: fontRegular, fontSize: 8)),
          ],
        ),
      ),
      pw.SizedBox(height: 8),
      pw.Text('2.2. Mô hình trạng thái chuẩn 4 pha: AsyncViewState<T>',
          style: pw.TextStyle(font: fontBold, fontSize: 10, color: PdfColors.blue800)),
      pw.SizedBox(height: 4),
      pw.Text(
        'Mọi màn hình tải dữ liệu đều xử lý đầy đủ 4 nhánh trạng thái: Loading (AppLoadingState), Empty (AppEmptyState), '
        'Error với cơ chế Retry (AppErrorState), và Data/Populated. Không để lộ màn hình trắng hoặc lỗi crash khi mất mạng.',
        style: pw.TextStyle(font: fontRegular, fontSize: 8.5),
      ),
      pw.SizedBox(height: 8),
      pw.Text('2.3. Design System & Bộ Token chuẩn hóa',
          style: pw.TextStyle(font: fontBold, fontSize: 10, color: PdfColors.blue800)),
      pw.SizedBox(height: 4),
      pw.Bullet(text: 'AppColors (lib/theme/app_colors.dart): Primary (#1D4ED8), Secondary (#0F766E), Success (#16845B), Warning (#B45309), Error (#B42318), OnPrimary (#FFFFFF). Loại bỏ 100% mã màu hardcode lẻ tẻ.', style: pw.TextStyle(font: fontRegular, fontSize: 8)),
      pw.Bullet(text: 'AppSpacing & AppRadius (lib/theme/app_spacing.dart): hairline (2), xxs (4), micro (6), xs (8), sm (12), md (16), lg (20), xl (24), xxl (32).', style: pw.TextStyle(font: fontRegular, fontSize: 8)),
      pw.Bullet(text: 'AppElevation: flat (0.0 - surfaces), overlay (6.0 - floating banner).', style: pw.TextStyle(font: fontRegular, fontSize: 8)),
      pw.Bullet(text: 'AppFontSize: caption (11), label (12), dense (13), displaySmall (18), heading (20), displayMedium (22), displayLarge (24).', style: pw.TextStyle(font: fontRegular, fontSize: 8)),
      pw.Bullet(text: 'Reusable Widgets (9 nhóm): AppButton, AppTextField, AppSearchBar, AppCard, AppBottomNav, CustomAppBar, AppConfirmDialog, AppLoadingState, AppEmptyState, AppErrorState.', style: pw.TextStyle(font: fontRegular, fontSize: 8)),
    ],
  ));

  // ----------------------------------------------------
  // TRANG 4: §3 FEATURES & USER FLOWS
  // ----------------------------------------------------
  doc.addPage(createPage(
    pageNum: 4,
    totalPages: totalPages,
    sectionTitle: '§3. Features & User Flows',
    content: [
      pw.Text('3.1. Danh mục 11 Màn hình và Ánh xạ Routing',
          style: pw.TextStyle(font: fontBold, fontSize: 11, color: PdfColors.blue900)),
      pw.SizedBox(height: 6),
      pw.Table(
        border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
        children: [
          pw.TableRow(
            decoration: const pw.BoxDecoration(color: PdfColors.blue50),
            children: [
              pw.Padding(padding: const pw.EdgeInsets.all(3), child: pw.Text('Route', style: pw.TextStyle(font: fontBold, fontSize: 7.5))),
              pw.Padding(padding: const pw.EdgeInsets.all(3), child: pw.Text('Screen Widget', style: pw.TextStyle(font: fontBold, fontSize: 7.5))),
              pw.Padding(padding: const pw.EdgeInsets.all(3), child: pw.Text('ViewModel', style: pw.TextStyle(font: fontBold, fontSize: 7.5))),
              pw.Padding(padding: const pw.EdgeInsets.all(3), child: pw.Text('Nguồn dữ liệu & Bộ sưu tập', style: pw.TextStyle(font: fontBold, fontSize: 7.5))),
            ],
          ),
          pw.TableRow(children: [
            pw.Padding(padding: const pw.EdgeInsets.all(3), child: pw.Text('/sign-in', style: pw.TextStyle(font: fontRegular, fontSize: 7.5))),
            pw.Padding(padding: const pw.EdgeInsets.all(3), child: pw.Text('SignInScreen', style: pw.TextStyle(font: fontRegular, fontSize: 7.5))),
            pw.Padding(padding: const pw.EdgeInsets.all(3), child: pw.Text('AuthViewModel', style: pw.TextStyle(font: fontRegular, fontSize: 7.5))),
            pw.Padding(padding: const pw.EdgeInsets.all(3), child: pw.Text('Firebase Auth (Google OAuth 2.0)', style: pw.TextStyle(font: fontRegular, fontSize: 7.5))),
          ]),
          pw.TableRow(children: [
            pw.Padding(padding: const pw.EdgeInsets.all(3), child: pw.Text('/home (Tab 0)', style: pw.TextStyle(font: fontRegular, fontSize: 7.5))),
            pw.Padding(padding: const pw.EdgeInsets.all(3), child: pw.Text('HomeScreen', style: pw.TextStyle(font: fontRegular, fontSize: 7.5))),
            pw.Padding(padding: const pw.EdgeInsets.all(3), child: pw.Text('AuthViewModel', style: pw.TextStyle(font: fontRegular, fontSize: 7.5))),
            pw.Padding(padding: const pw.EdgeInsets.all(3), child: pw.Text('Tổng quan trạng thái, shortcut điều hướng', style: pw.TextStyle(font: fontRegular, fontSize: 7.5))),
          ]),
          pw.TableRow(children: [
            pw.Padding(padding: const pw.EdgeInsets.all(3), child: pw.Text('/home (Tab 1)', style: pw.TextStyle(font: fontRegular, fontSize: 7.5))),
            pw.Padding(padding: const pw.EdgeInsets.all(3), child: pw.Text('RoadmapScreen', style: pw.TextStyle(font: fontRegular, fontSize: 7.5))),
            pw.Padding(padding: const pw.EdgeInsets.all(3), child: pw.Text('RoadmapViewModel', style: pw.TextStyle(font: fontRegular, fontSize: 7.5))),
            pw.Padding(padding: const pw.EdgeInsets.all(3), child: pw.Text('Firestore: `courses` + passedCourses', style: pw.TextStyle(font: fontRegular, fontSize: 7.5))),
          ]),
          pw.TableRow(children: [
            pw.Padding(padding: const pw.EdgeInsets.all(3), child: pw.Text('/course-detail', style: pw.TextStyle(font: fontRegular, fontSize: 7.5))),
            pw.Padding(padding: const pw.EdgeInsets.all(3), child: pw.Text('CourseDetailScreen', style: pw.TextStyle(font: fontRegular, fontSize: 7.5))),
            pw.Padding(padding: const pw.EdgeInsets.all(3), child: pw.Text('RoadmapViewModel', style: pw.TextStyle(font: fontRegular, fontSize: 7.5))),
            pw.Padding(padding: const pw.EdgeInsets.all(3), child: pw.Text('Chi tiết slot, môn tiên quyết, danh sách bài tập', style: pw.TextStyle(font: fontRegular, fontSize: 7.5))),
          ]),
          pw.TableRow(children: [
            pw.Padding(padding: const pw.EdgeInsets.all(3), child: pw.Text('/home (Tab 2)', style: pw.TextStyle(font: fontRegular, fontSize: 7.5))),
            pw.Padding(padding: const pw.EdgeInsets.all(3), child: pw.Text('TasksScreen', style: pw.TextStyle(font: fontRegular, fontSize: 7.5))),
            pw.Padding(padding: const pw.EdgeInsets.all(3), child: pw.Text('TasksViewModel', style: pw.TextStyle(font: fontRegular, fontSize: 7.5))),
            pw.Padding(padding: const pw.EdgeInsets.all(3), child: pw.Text('Firestore: `users/{uid}/tasks`', style: pw.TextStyle(font: fontRegular, fontSize: 7.5))),
          ]),
          pw.TableRow(children: [
            pw.Padding(padding: const pw.EdgeInsets.all(3), child: pw.Text('/home (Tab 3)', style: pw.TextStyle(font: fontRegular, fontSize: 7.5))),
            pw.Padding(padding: const pw.EdgeInsets.all(3), child: pw.Text('NotesScreen', style: pw.TextStyle(font: fontRegular, fontSize: 7.5))),
            pw.Padding(padding: const pw.EdgeInsets.all(3), child: pw.Text('NotesViewModel', style: pw.TextStyle(font: fontRegular, fontSize: 7.5))),
            pw.Padding(padding: const pw.EdgeInsets.all(3), child: pw.Text('Firestore: `users/{uid}/notes`', style: pw.TextStyle(font: fontRegular, fontSize: 7.5))),
          ]),
          pw.TableRow(children: [
            pw.Padding(padding: const pw.EdgeInsets.all(3), child: pw.Text('/note-editor', style: pw.TextStyle(font: fontRegular, fontSize: 7.5))),
            pw.Padding(padding: const pw.EdgeInsets.all(3), child: pw.Text('NoteEditorScreen', style: pw.TextStyle(font: fontRegular, fontSize: 7.5))),
            pw.Padding(padding: const pw.EdgeInsets.all(3), child: pw.Text('NotesViewModel', style: pw.TextStyle(font: fontRegular, fontSize: 7.5))),
            pw.Padding(padding: const pw.EdgeInsets.all(3), child: pw.Text('Soạn thảo ghi chú, đính kèm file Cloud Storage', style: pw.TextStyle(font: fontRegular, fontSize: 7.5))),
          ]),
          pw.TableRow(children: [
            pw.Padding(padding: const pw.EdgeInsets.all(3), child: pw.Text('/advisor', style: pw.TextStyle(font: fontRegular, fontSize: 7.5))),
            pw.Padding(padding: const pw.EdgeInsets.all(3), child: pw.Text('AdvisorScreen', style: pw.TextStyle(font: fontRegular, fontSize: 7.5))),
            pw.Padding(padding: const pw.EdgeInsets.all(3), child: pw.Text('AdvisorViewModel', style: pw.TextStyle(font: fontRegular, fontSize: 7.5))),
            pw.Padding(padding: const pw.EdgeInsets.all(3), child: pw.Text('Quy tắc học vụ nội bộ, 4 cấp tư vấn, consent dialog', style: pw.TextStyle(font: fontRegular, fontSize: 7.5))),
          ]),
          pw.TableRow(children: [
            pw.Padding(padding: const pw.EdgeInsets.all(3), child: pw.Text('/strategy-sim', style: pw.TextStyle(font: fontRegular, fontSize: 7.5))),
            pw.Padding(padding: const pw.EdgeInsets.all(3), child: pw.Text('StrategySimScreen', style: pw.TextStyle(font: fontRegular, fontSize: 7.5))),
            pw.Padding(padding: const pw.EdgeInsets.all(3), child: pw.Text('AdvisorViewModel', style: pw.TextStyle(font: fontRegular, fontSize: 7.5))),
            pw.Padding(padding: const pw.EdgeInsets.all(3), child: pw.Text('Mô phỏng điểm số, GPA kỳ 5, phân loại danh hiệu', style: pw.TextStyle(font: fontRegular, fontSize: 7.5))),
          ]),
          pw.TableRow(children: [
            pw.Padding(padding: const pw.EdgeInsets.all(3), child: pw.Text('/sync-vault', style: pw.TextStyle(font: fontRegular, fontSize: 7.5))),
            pw.Padding(padding: const pw.EdgeInsets.all(3), child: pw.Text('SyncVaultScreen', style: pw.TextStyle(font: fontRegular, fontSize: 7.5))),
            pw.Padding(padding: const pw.EdgeInsets.all(3), child: pw.Text('AuthViewModel, Export', style: pw.TextStyle(font: fontRegular, fontSize: 7.5))),
            pw.Padding(padding: const pw.EdgeInsets.all(3), child: pw.Text('Firebase Demo Area: Sync, Remote Config, Crashlytics, PDF', style: pw.TextStyle(font: fontRegular, fontSize: 7.5))),
          ]),
          pw.TableRow(children: [
            pw.Padding(padding: const pw.EdgeInsets.all(3), child: pw.Text('/notifications', style: pw.TextStyle(font: fontRegular, fontSize: 7.5))),
            pw.Padding(padding: const pw.EdgeInsets.all(3), child: pw.Text('NotificationsScreen', style: pw.TextStyle(font: fontRegular, fontSize: 7.5))),
            pw.Padding(padding: const pw.EdgeInsets.all(3), child: pw.Text('NotificationsViewModel', style: pw.TextStyle(font: fontRegular, fontSize: 7.5))),
            pw.Padding(padding: const pw.EdgeInsets.all(3), child: pw.Text('Firestore: `users/{uid}/notifications`, FCM center', style: pw.TextStyle(font: fontRegular, fontSize: 7.5))),
          ]),
        ],
      ),
      pw.SizedBox(height: 10),
      pw.Text('3.2. Ba Luồng nghiệp vụ chính (User Flows)',
          style: pw.TextStyle(font: fontBold, fontSize: 10, color: PdfColors.blue800)),
      pw.SizedBox(height: 4),
      pw.Bullet(text: 'Flow 1 (Curriculum & Prerequisite Check): Xem danh mục môn kỳ Fall 2024 từ Firestore `courses`; tự động đối chiếu điều kiện tiên quyết với `passedCourses`; cảnh báo môn thiếu; xem chi tiết Course Detail với 4 states.', style: pw.TextStyle(font: fontRegular, fontSize: 8)),
      pw.Bullet(text: 'Flow 2 (Study Plan & Notes Vault): CRUD công việc với Firestore; xử lý optimistic rollback khi ghi thất bại; soạn thảo và đọc ghi chú; hỗ trợ đính kèm file Cloud Storage; lưu trữ trạng thái offline với serverAndCache.', style: pw.TextStyle(font: fontRegular, fontSize: 8)),
      pw.Bullet(text: 'Flow 3 (Cố vấn học tập 4 cấp & Academic Strategy): Hỗ trợ 4 cấp độ tư vấn rõ rệt (Môn học, Kỳ học, Chương trình, Điểm số) có bộ chọn UI ChoiceChip; bắt buộc xác nhận quyền chia sẻ dữ liệu qua dialog _askConsent() (fail-closed); hiển thị banner lỗi và cho phép "Thử lại"; mô phỏng chiến lược GPA.', style: pw.TextStyle(font: fontRegular, fontSize: 8)),
      pw.SizedBox(height: 6),
      pw.Text('3.3. Tính năng Xuất Báo cáo Học tập (Study Report PDF)',
          style: pw.TextStyle(font: fontBold, fontSize: 10, color: PdfColors.blue800)),
      pw.SizedBox(height: 4),
      pw.Text('Tích hợp ReportPdfService và ReportExportService sử dụng package pdf/printing. Quá trình xuất báo cáo gồm: '
          '(1) Dialog xin quyền chia sẻ; (2) Kết xuất PDF với font Unicode DejaVu Sans; (3) Upload lên Storage reports/{uid}/ có thanh tiến độ %; '
          '(4) Lưu metadata vào Firestore; (5) Mở Share Sheet in/chia sẻ file.', style: pw.TextStyle(font: fontRegular, fontSize: 8)),
    ],
  ));

  // ----------------------------------------------------
  // TRANG 5: §4 FIREBASE INTEGRATION
  // ----------------------------------------------------
  doc.addPage(createPage(
    pageNum: 5,
    totalPages: totalPages,
    sectionTitle: '§4. Firebase Integration',
    content: [
      pw.Text('4.1. Thiết lập Firebase Project & Cấu hình Android',
          style: pw.TextStyle(font: fontBold, fontSize: 11, color: PdfColors.blue900)),
      pw.SizedBox(height: 6),
      pw.Text(
        'Dự án kết nối với Firebase Project `prm323-lab2-gr6` (Google Cloud Project Number được bảo mật). '
        'File cấu hình máy khách `android/app/google-services.json` được định tuyến độc lập, không đưa vào kho mã nguồn Git công khai '
        'nhằm tuân thủ nguyên tắc an toàn thông tin theo Rubric §13.',
        style: pw.TextStyle(font: fontRegular, fontSize: 8.5),
      ),
      pw.SizedBox(height: 8),
      pw.Text('4.2. Google Authentication & Ràng buộc miền sinh viên (@fpt.edu.vn)',
          style: pw.TextStyle(font: fontBold, fontSize: 10, color: PdfColors.blue800)),
      pw.SizedBox(height: 4),
      pw.Text(
        'Luồng đăng nhập được kiểm soát chặt chẽ bởi 2 lớp phòng vệ (Defense in Depth):\n'
        '• Lớp 1 (Client OAuth Filter): Cấu hình GoogleSignIn với hostedDomain: "fpt.edu.vn" để lọc danh sách tài khoản.\n'
        '• Lớp 2 (Server/Code Gate): Sau khi nhận credential thành công, FirebaseAuthService kiểm tra chặt chẽ email.endsWith("@fpt.edu.vn"). '
        'Nếu người dùng đăng nhập bằng tài khoản ngoài (như @gmail.com), hệ thống lập tức gọi signOut(), xóa phiên làm việc cục bộ, '
        'và trả về AuthException("Chỉ chấp nhận tài khoản email sinh viên FPT (@fpt.edu.vn)").',
        style: pw.TextStyle(font: fontRegular, fontSize: 8.5),
      ),
      pw.SizedBox(height: 8),
      pw.Text('4.3. Cloud Firestore & Kiến trúc Security Rules',
          style: pw.TextStyle(font: fontBold, fontSize: 10, color: PdfColors.blue800)),
      pw.SizedBox(height: 4),
      pw.Text(
        'Toàn bộ dữ liệu cá nhân của người dùng được lưu trữ phân cấp dưới đường dẫn: `users/{userId}/{collection}` '
        'bao gồm: `tasks`, `notes`, `notifications`, `tokens`, `sync`. Dữ liệu danh mục chung gồm: `courses` và `curriculums`.',
        style: pw.TextStyle(font: fontRegular, fontSize: 8.5),
      ),
      pw.SizedBox(height: 4),
      pw.Container(
        padding: const pw.EdgeInsets.all(6),
        decoration: pw.BoxDecoration(color: PdfColors.grey100, border: pw.Border.all(color: PdfColors.grey300, width: 0.5)),
        child: pw.Text(
          '// Trích xuất firestore.rules — Tuyệt đối không dùng "allow read, write: if true"\n'
          'rules_version = \'2\';\n'
          'service cloud.firestore {\n'
          '  match /databases/{database}/documents {\n'
          '    function isAuthenticated() { return request.auth != null; }\n'
          '    function isOwner(userId) { return isAuthenticated() && request.auth.uid == userId; }\n'
          '    match /courses/{courseId} { allow read: if isAuthenticated(); allow write: if false; }\n'
          '    match /users/{userId}/{document=**} { allow read, write: if isOwner(userId); }\n'
          '    match /{document=**} { allow read, write: if false; } // Default-deny tail\n'
          '  }\n'
          '}',
          style: pw.TextStyle(font: fontRegular, fontSize: 7, color: PdfColors.blue900),
        ),
      ),
      pw.SizedBox(height: 8),
      pw.Text('4.4. Cloud Storage & Phân quyền file đính kèm/Báo cáo',
          style: pw.TextStyle(font: fontBold, fontSize: 10, color: PdfColors.blue800)),
      pw.SizedBox(height: 4),
      pw.Text(
        'Đường dẫn lưu trữ: `reports/{userId}/{fileName}` và `notes/{userId}/{fileName}`. '
        'Storage rules yêu cầu xác thực `request.auth.uid == userId`, đồng thời kiểm tra định dạng file (chỉ cho phép upload application/pdf '
        'vào thư mục reports) và kích thước không vượt quá 10MB.',
        style: pw.TextStyle(font: fontRegular, fontSize: 8.5),
      ),
      pw.SizedBox(height: 6),
      pw.Container(
        padding: const pw.EdgeInsets.all(6),
        decoration: pw.BoxDecoration(color: PdfColors.yellow50, border: pw.Border.all(color: PdfColors.amber800, width: 0.5)),
        child: pw.Text(
          '[⏳ CHỜ ẢNH RUNTIME]: Ảnh chụp Firebase Authentication Console (danh sách user test), '
          'Firestore Console (cây document users/{uid}), và Cloud Storage Console (file study_report_*.pdf).',
          style: pw.TextStyle(font: fontRegular, fontSize: 7.5, color: PdfColors.brown900),
        ),
      ),
    ],
  ));

  // ----------------------------------------------------
  // TRANG 6: §5 FIREBASE SERVICES
  // ----------------------------------------------------
  doc.addPage(createPage(
    pageNum: 6,
    totalPages: totalPages,
    sectionTitle: '§5. Firebase Services',
    content: [
      pw.Text('5.1. Firebase Analytics — Kế hoạch 13 Custom Events',
          style: pw.TextStyle(font: fontBold, fontSize: 11, color: PdfColors.blue900)),
      pw.SizedBox(height: 6),
      pw.Text(
        'Ứng dụng xây dựng kế hoạch phân tích 13 sự kiện tùy chỉnh (vượt yêu cầu tối thiểu 7 sự kiện của rubric). '
        'Sau khi đăng nhập thành công, hệ thống lập tức gọi setUserId(uid) để phân khúc dữ liệu người dùng. '
        'Chính sách bảo mật: Toàn bộ tham số được lọc bỏ thông tin nhạy cảm (PII: không gửi email, tên thật, nội dung note).',
        style: pw.TextStyle(font: fontRegular, fontSize: 8.5),
      ),
      pw.SizedBox(height: 4),
      pw.Bullet(text: 'Danh sách sự kiện chính: login_success, course_view, prerequisite_check, search_course, task_create, task_complete, note_create, advisor_query, sync_triggered, export_report, notification_received, strategy_view, strategy_preset_applied.', style: pw.TextStyle(font: fontRegular, fontSize: 8)),
      pw.SizedBox(height: 8),
      pw.Text('5.2. Firebase Crashlytics — Bắt lỗi & Custom Keys',
          style: pw.TextStyle(font: fontBold, fontSize: 10, color: PdfColors.blue800)),
      pw.SizedBox(height: 4),
      pw.Text(
        'Crashlytics được khởi tạo tự động hook vào FlutterError.onError và PlatformDispatcher.instance.onError. '
        'Khi user đăng nhập, hệ thống gán userIdentifier và thiết lập Custom Key auth_method = "google". '
        'Màn hình SyncVaultScreen cung cấp nút "Gửi test Crashlytics non-fatal" để chủ động kiểm tra đường truyền log về console.',
        style: pw.TextStyle(font: fontRegular, fontSize: 8.5),
      ),
      pw.SizedBox(height: 8),
      pw.Text('5.3. Firebase Remote Config — Feature Flags & Version Gate',
          style: pw.TextStyle(font: fontBold, fontSize: 10, color: PdfColors.blue800)),
      pw.SizedBox(height: 4),
      pw.Text(
        'Được cấu hình thông qua RemoteConfigService với file mặc định `firebase/remote-config-defaults.json`. Gồm 5 tham số cốt lõi:\n'
        '• maintenance_mode (bool): Chuyển toàn bộ app sang MaintenanceScreen khi kích hoạt.\n'
        '• min_app_version (string): Cơ chế Cổng chặn phiên bản (Version Gate). Được kiểm tra ngay tại AuthGate thông qua tiện ích thuần '
        'lib/utils/version_utils.dart. Nếu phiên bản app thấp hơn min_app_version, ứng dụng chặn điều hướng và hiển thị VersionBlockedScreen.\n'
        '• feature_ai_advisor_enabled (bool): Bật/tắt tính năng Cố vấn học tập.\n'
        '• banner_message (string) & sync_interval_seconds (int): Tùy biến thông điệp và chu kỳ đồng bộ.',
        style: pw.TextStyle(font: fontRegular, fontSize: 8.5),
      ),
      pw.SizedBox(height: 8),
      pw.Text('5.4. Firebase Cloud Messaging (FCM) & Xử lý 3 Trạng thái',
          style: pw.TextStyle(font: fontBold, fontSize: 10, color: PdfColors.blue800)),
      pw.SizedBox(height: 4),
      pw.Text(
        'Hệ thống tự động xin quyền notification trên Android 13+ (POST_NOTIFICATIONS) và lưu token FCM vào `users/{uid}/tokens`:\n'
        '• Foreground (Ứng dụng đang mở): Bắt qua onMessage, hiển thị banner nổi ForegroundPushBanner (elevation 6.0, Semantics liveRegion).\n'
        '• Background (Ứng dụng chạy ngầm): Xử lý qua top-level handler firebaseMessagingBackgroundHandler.\n'
        '• Terminated (Ứng dụng bị đóng): Bắt qua getInitialMessage() khi mở app.\n'
        '• Điều hướng khi chạm: Payload mang data `route` và `course_id` được giải mã để tự động mở đúng màn hình chi tiết tương ứng.',
        style: pw.TextStyle(font: fontRegular, fontSize: 8.5),
      ),
      pw.SizedBox(height: 4),
      pw.Container(
        padding: const pw.EdgeInsets.all(6),
        decoration: pw.BoxDecoration(color: PdfColors.yellow50, border: pw.Border.all(color: PdfColors.amber800, width: 0.5)),
        child: pw.Text(
          '[⏳ CHỜ ẢNH RUNTIME]: Ảnh chụp DebugView 13 events, Dashboard Crashlytics với custom key, '
          'Remote Config trước/sau khi đổi giá trị trên Console, và 3 trạng thái nhận tin nhắn FCM.',
          style: pw.TextStyle(font: fontRegular, fontSize: 7.5, color: PdfColors.brown900),
        ),
      ),
    ],
  ));

  // ----------------------------------------------------
  // TRANG 7: §6 TESTING STRATEGY
  // ----------------------------------------------------
  doc.addPage(createPage(
    pageNum: 7,
    totalPages: totalPages,
    sectionTitle: '§6. Testing Strategy & Unit Tests',
    content: [
      pw.Text('6.1. Chiến lược Kim tự tháp Kiểm thử (Testing Pyramid)',
          style: pw.TextStyle(font: fontBold, fontSize: 11, color: PdfColors.blue900)),
      pw.SizedBox(height: 6),
      pw.Text(
        'Dự án triển khai kiểm thử nhiều tầng, phân định minh bạch giữa kiểm thử đơn vị kín (Hermetic Unit/Widget Tests) '
        'và kiểm thử chấp nhận đầu cuối trên thiết bị thật (Runtime E2E Tests).',
        style: pw.TextStyle(font: fontRegular, fontSize: 8.5),
      ),
      pw.SizedBox(height: 8),
      pw.Text('6.2. Kết quả Kiểm thử Tự động Cục bộ (Hermetic Suite)',
          style: pw.TextStyle(font: fontBold, fontSize: 10, color: PdfColors.blue800)),
      pw.SizedBox(height: 4),
      pw.Table(
        border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
        children: [
          pw.TableRow(
            decoration: const pw.BoxDecoration(color: PdfColors.blue50),
            children: [
              pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('Lệnh kiểm tra', style: pw.TextStyle(font: fontBold, fontSize: 8))),
              pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('Mục tiêu kiểm tra', style: pw.TextStyle(font: fontBold, fontSize: 8))),
              pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('Kết quả thực tế', style: pw.TextStyle(font: fontBold, fontSize: 8))),
              pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('Trạng thái', style: pw.TextStyle(font: fontBold, fontSize: 8))),
            ],
          ),
          pw.TableRow(children: [
            pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('flutter analyze', style: pw.TextStyle(font: fontRegular, fontSize: 8))),
            pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('Phân tích cú pháp, type safety, lint rules, import rules', style: pw.TextStyle(font: fontRegular, fontSize: 7.5))),
            pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('No issues found! (ran in 10.6s) — 0 warnings, 0 errors', style: pw.TextStyle(font: fontRegular, fontSize: 7.5))),
            pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('PASS (Exit 0)', style: pw.TextStyle(font: fontBold, fontSize: 8, color: PdfColors.green800))),
          ]),
          pw.TableRow(children: [
            pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('flutter test', style: pw.TextStyle(font: fontRegular, fontSize: 8))),
            pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('Bộ test đơn vị và test widget toàn diện', style: pw.TextStyle(font: fontRegular, fontSize: 7.5))),
            pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('89/89 tests passed (100% pass, 0 fail, 0 skip)', style: pw.TextStyle(font: fontRegular, fontSize: 7.5))),
            pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('PASS (Exit 0)', style: pw.TextStyle(font: fontBold, fontSize: 8, color: PdfColors.green800))),
          ]),
          pw.TableRow(children: [
            pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('flutter build apk --debug', style: pw.TextStyle(font: fontRegular, fontSize: 8))),
            pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('Biên dịch file APK Android hoàn chỉnh qua Gradle', style: pw.TextStyle(font: fontRegular, fontSize: 7.5))),
            pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('Built build/app/outputs/flutter-apk/app-debug.apk', style: pw.TextStyle(font: fontRegular, fontSize: 7.5))),
            pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('PASS (Exit 0)', style: pw.TextStyle(font: fontBold, fontSize: 8, color: PdfColors.green800))),
          ]),
        ],
      ),
      pw.SizedBox(height: 8),
      pw.Text('6.3. Phân bố 89 Ca Kiểm thử Đơn vị & Widget',
          style: pw.TextStyle(font: fontBold, fontSize: 10, color: PdfColors.blue800)),
      pw.SizedBox(height: 4),
      pw.Bullet(text: 'test/services/version_gate_test.dart (16 tests): So sánh phiên bản semver (lớn hơn, nhỏ hơn, bằng nhau, ký tự phụ, fallback an toàn).', style: pw.TextStyle(font: fontRegular, fontSize: 8)),
      pw.Bullet(text: 'test/services/remote_config_service_test.dart (12 tests): Khởi tạo tham số mặc định, fetchAndActivate, assert schema khớp remote-config-defaults.json.', style: pw.TextStyle(font: fontRegular, fontSize: 8)),
      pw.Bullet(text: 'test/services/report_export_service_test.dart (10 tests): Quá trình xuất PDF, metadata Firestore, log Analytics, bắt lỗi upload.', style: pw.TextStyle(font: fontRegular, fontSize: 8)),
      pw.Bullet(text: 'test/viewmodels/advisor_viewmodel_test.dart (9 tests): Kiểm thử 4 cấp tư vấn, cơ chế Share Consent fail-closed, lưu lịch sử, bắt lỗi và phục hồi câu hỏi.', style: pw.TextStyle(font: fontRegular, fontSize: 8)),
      pw.Bullet(text: 'test/viewmodels/auth_viewmodel_test.dart (8 tests): Đăng nhập thành công, từ chối tài khoản ngoài fpt.edu.vn, hủy đăng nhập, đăng xuất clear state.', style: pw.TextStyle(font: fontRegular, fontSize: 8)),
      pw.Bullet(text: 'test/viewmodels/tasks_notes_viewmodel_test.dart (18 tests): CRUD tasks và notes, optimistic rollback khi mất mạng, parse Firestore Timestamp.', style: pw.TextStyle(font: fontRegular, fontSize: 8)),
      pw.Bullet(text: 'test/widget_test.dart (16 tests): Kiểm thử giao diện SignInScreen, CourseDetailScreen 4 trạng thái, Notification Center, Dialog xác nhận.', style: pw.TextStyle(font: fontRegular, fontSize: 8)),
      pw.SizedBox(height: 6),
      pw.Container(
        padding: const pw.EdgeInsets.all(6),
        decoration: const pw.BoxDecoration(color: PdfColors.blue50),
        child: pw.Text(
          'LƯU Ý QUAN TRỌNG: 89 test cases trên chạy với Hermetic Fakes (Test Doubles) trong môi trường CI/local, '
          'không tương tác với Firebase Cloud thật. Không được coi 89 test unit này là bằng chứng thay thế cho ARTEMIS E2E.',
          style: pw.TextStyle(font: fontRegular, fontSize: 7.5, color: PdfColors.blue900),
        ),
      ),
    ],
  ));

  // ----------------------------------------------------
  // TRANG 8: §7 ARTEMIS E2E TESTING
  // ----------------------------------------------------
  doc.addPage(createPage(
    pageNum: 8,
    totalPages: totalPages,
    sectionTitle: '§7. ARTEMIS E2E Testing',
    content: [
      pw.Text('7.1. Tổng quan Bộ kiểm thử ARTEMIS E2E (e2e_test/)',
          style: pw.TextStyle(font: fontBold, fontSize: 11, color: PdfColors.blue900)),
      pw.SizedBox(height: 6),
      pw.Text(
        'Bộ kiểm thử tự động trên thiết bị di động được xây dựng dựa trên framework Google ARTEMIS và Python Pytest. '
        'Đã hoàn thiện 26 kịch bản kiểm thử (test cases) tại thư mục `e2e_test/`, đáp ứng đầy đủ yêu cầu tối thiểu 10 ca kiểm thử của rubric.',
        style: pw.TextStyle(font: fontRegular, fontSize: 8.5),
      ),
      pw.SizedBox(height: 6),
      pw.Table(
        border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
        children: [
          pw.TableRow(
            decoration: const pw.BoxDecoration(color: PdfColors.blue50),
            children: [
              pw.Padding(padding: const pw.EdgeInsets.all(3), child: pw.Text('Mã TC', style: pw.TextStyle(font: fontBold, fontSize: 7.5))),
              pw.Padding(padding: const pw.EdgeInsets.all(3), child: pw.Text('Kịch bản kiểm thử (Scenario)', style: pw.TextStyle(font: fontBold, fontSize: 7.5))),
              pw.Padding(padding: const pw.EdgeInsets.all(3), child: pw.Text('Mô hình', style: pw.TextStyle(font: fontBold, fontSize: 7.5))),
              pw.Padding(padding: const pw.EdgeInsets.all(3), child: pw.Text('Trạng thái thực thi', style: pw.TextStyle(font: fontBold, fontSize: 7.5))),
            ],
          ),
          pw.TableRow(children: [
            pw.Padding(padding: const pw.EdgeInsets.all(3), child: pw.Text('TC-01', style: pw.TextStyle(font: fontRegular, fontSize: 7.5))),
            pw.Padding(padding: const pw.EdgeInsets.all(3), child: pw.Text('Đăng nhập Google Sign-In hợp lệ (@fpt.edu.vn)', style: pw.TextStyle(font: fontRegular, fontSize: 7.5))),
            pw.Padding(padding: const pw.EdgeInsets.all(3), child: pw.Text('Flash', style: pw.TextStyle(font: fontRegular, fontSize: 7.5))),
            pw.Padding(padding: const pw.EdgeInsets.all(3), child: pw.Text('BLOCKED (Quota 429)', style: pw.TextStyle(font: fontBold, fontSize: 7.5, color: PdfColors.red800))),
          ]),
          pw.TableRow(children: [
            pw.Padding(padding: const pw.EdgeInsets.all(3), child: pw.Text('TC-02', style: pw.TextStyle(font: fontRegular, fontSize: 7.5))),
            pw.Padding(padding: const pw.EdgeInsets.all(3), child: pw.Text('Từ chối đăng nhập với email ngoài miền FPT', style: pw.TextStyle(font: fontRegular, fontSize: 7.5))),
            pw.Padding(padding: const pw.EdgeInsets.all(3), child: pw.Text('Flash', style: pw.TextStyle(font: fontRegular, fontSize: 7.5))),
            pw.Padding(padding: const pw.EdgeInsets.all(3), child: pw.Text('BLOCKED (Quota 429)', style: pw.TextStyle(font: fontBold, fontSize: 7.5, color: PdfColors.red800))),
          ]),
          pw.TableRow(children: [
            pw.Padding(padding: const pw.EdgeInsets.all(3), child: pw.Text('TC-03', style: pw.TextStyle(font: fontRegular, fontSize: 7.5))),
            pw.Padding(padding: const pw.EdgeInsets.all(3), child: pw.Text('Tải danh mục môn học & hiển thị điều kiện tiên quyết', style: pw.TextStyle(font: fontRegular, fontSize: 7.5))),
            pw.Padding(padding: const pw.EdgeInsets.all(3), child: pw.Text('Flash', style: pw.TextStyle(font: fontRegular, fontSize: 7.5))),
            pw.Padding(padding: const pw.EdgeInsets.all(3), child: pw.Text('BLOCKED (Quota 429)', style: pw.TextStyle(font: fontBold, fontSize: 7.5, color: PdfColors.red800))),
          ]),
          pw.TableRow(children: [
            pw.Padding(padding: const pw.EdgeInsets.all(3), child: pw.Text('TC-04', style: pw.TextStyle(font: fontRegular, fontSize: 7.5))),
            pw.Padding(padding: const pw.EdgeInsets.all(3), child: pw.Text('Tìm kiếm môn học theo mã/tên và kiểm tra kết quả', style: pw.TextStyle(font: fontRegular, fontSize: 7.5))),
            pw.Padding(padding: const pw.EdgeInsets.all(3), child: pw.Text('Flash', style: pw.TextStyle(font: fontRegular, fontSize: 7.5))),
            pw.Padding(padding: const pw.EdgeInsets.all(3), child: pw.Text('BLOCKED (Quota 429)', style: pw.TextStyle(font: fontBold, fontSize: 7.5, color: PdfColors.red800))),
          ]),
          pw.TableRow(children: [
            pw.Padding(padding: const pw.EdgeInsets.all(3), child: pw.Text('TC-05', style: pw.TextStyle(font: fontRegular, fontSize: 7.5))),
            pw.Padding(padding: const pw.EdgeInsets.all(3), child: pw.Text('Thao tác tạo công việc và chuyển trạng thái hoàn thành', style: pw.TextStyle(font: fontRegular, fontSize: 7.5))),
            pw.Padding(padding: const pw.EdgeInsets.all(3), child: pw.Text('Pro', style: pw.TextStyle(font: fontRegular, fontSize: 7.5))),
            pw.Padding(padding: const pw.EdgeInsets.all(3), child: pw.Text('BLOCKED (Quota 429)', style: pw.TextStyle(font: fontBold, fontSize: 7.5, color: PdfColors.red800))),
          ]),
          pw.TableRow(children: [
            pw.Padding(padding: const pw.EdgeInsets.all(3), child: pw.Text('TC-06', style: pw.TextStyle(font: fontRegular, fontSize: 7.5))),
            pw.Padding(padding: const pw.EdgeInsets.all(3), child: pw.Text('Soạn thảo ghi chú mới và lưu trữ vào Firestore', style: pw.TextStyle(font: fontRegular, fontSize: 7.5))),
            pw.Padding(padding: const pw.EdgeInsets.all(3), child: pw.Text('Pro', style: pw.TextStyle(font: fontRegular, fontSize: 7.5))),
            pw.Padding(padding: const pw.EdgeInsets.all(3), child: pw.Text('BLOCKED (Quota 429)', style: pw.TextStyle(font: fontBold, fontSize: 7.5, color: PdfColors.red800))),
          ]),
          pw.TableRow(children: [
            pw.Padding(padding: const pw.EdgeInsets.all(3), child: pw.Text('TC-07', style: pw.TextStyle(font: fontRegular, fontSize: 7.5))),
            pw.Padding(padding: const pw.EdgeInsets.all(3), child: pw.Text('Đồng bộ Vault thủ công và xác thực dữ liệu', style: pw.TextStyle(font: fontRegular, fontSize: 7.5))),
            pw.Padding(padding: const pw.EdgeInsets.all(3), child: pw.Text('Pro', style: pw.TextStyle(font: fontRegular, fontSize: 7.5))),
            pw.Padding(padding: const pw.EdgeInsets.all(3), child: pw.Text('BLOCKED (Quota 429)', style: pw.TextStyle(font: fontBold, fontSize: 7.5, color: PdfColors.red800))),
          ]),
          pw.TableRow(children: [
            pw.Padding(padding: const pw.EdgeInsets.all(3), child: pw.Text('TC-08', style: pw.TextStyle(font: fontRegular, fontSize: 7.5))),
            pw.Padding(padding: const pw.EdgeInsets.all(3), child: pw.Text('Kiểm tra ngắt mạng (Offline mode) và phục hồi khi có mạng', style: pw.TextStyle(font: fontRegular, fontSize: 7.5))),
            pw.Padding(padding: const pw.EdgeInsets.all(3), child: pw.Text('Pro', style: pw.TextStyle(font: fontRegular, fontSize: 7.5))),
            pw.Padding(padding: const pw.EdgeInsets.all(3), child: pw.Text('BLOCKED (Quota 429)', style: pw.TextStyle(font: fontBold, fontSize: 7.5, color: PdfColors.red800))),
          ]),
          pw.TableRow(children: [
            pw.Padding(padding: const pw.EdgeInsets.all(3), child: pw.Text('TC-09', style: pw.TextStyle(font: fontRegular, fontSize: 7.5))),
            pw.Padding(padding: const pw.EdgeInsets.all(3), child: pw.Text('Hỏi đáp Cố vấn học tập, xác nhận consent và thử lại lỗi', style: pw.TextStyle(font: fontRegular, fontSize: 7.5))),
            pw.Padding(padding: const pw.EdgeInsets.all(3), child: pw.Text('Pro', style: pw.TextStyle(font: fontRegular, fontSize: 7.5))),
            pw.Padding(padding: const pw.EdgeInsets.all(3), child: pw.Text('BLOCKED (Quota 429)', style: pw.TextStyle(font: fontBold, fontSize: 7.5, color: PdfColors.red800))),
          ]),
          pw.TableRow(children: [
            pw.Padding(padding: const pw.EdgeInsets.all(3), child: pw.Text('TC-10', style: pw.TextStyle(font: fontRegular, fontSize: 7.5))),
            pw.Padding(padding: const pw.EdgeInsets.all(3), child: pw.Text('Xuất báo cáo PDF, theo dõi tiến trình và chia sẻ', style: pw.TextStyle(font: fontRegular, fontSize: 7.5))),
            pw.Padding(padding: const pw.EdgeInsets.all(3), child: pw.Text('Pro', style: pw.TextStyle(font: fontRegular, fontSize: 7.5))),
            pw.Padding(padding: const pw.EdgeInsets.all(3), child: pw.Text('BLOCKED (Quota 429)', style: pw.TextStyle(font: fontBold, fontSize: 7.5, color: PdfColors.red800))),
          ]),
        ],
      ),
      pw.SizedBox(height: 8),
      pw.Text('7.2. Báo cáo Sự cố Hạ tầng: Gemini API Quota 429',
          style: pw.TextStyle(font: fontBold, fontSize: 10, color: PdfColors.red800)),
      pw.SizedBox(height: 4),
      pw.Text(
        'Theo nhật ký kiểm thử chi tiết tại evidence/artemis/RUN_LOG_2026-11-04.md: Máy chủ ARTEMIS và Android Emulator (emulator-5554) '
        'đã sẵn sàng (overall_ready: true). Tuy nhiên, khi gửi lệnh chạy kiểm thử, hệ thống gặp lỗi HTTP 429 RESOURCE_EXHAUSTED từ Google Gemini API '
        '(giới hạn gói Free Tier 20 requests/ngày cho model gemini-3.8-flash đã cạn kiệt, cần chờ reset hoặc nạp key có phí).\n\n'
        'Tuân thủ tuyệt đối quy định không giả mạo kết quả kiểm thử (Never fabricate test pass), toàn bộ bảng kết quả 3 lần chạy '
        'được giữ ở trạng thái BLOCKED và chờ chạy lại ngay khi hạn ngạch được phục hồi.',
        style: pw.TextStyle(font: fontRegular, fontSize: 8),
      ),
    ],
  ));

  // ----------------------------------------------------
  // TRANG 9: §8 AI CODE REVIEW
  // ----------------------------------------------------
  doc.addPage(createPage(
    pageNum: 9,
    totalPages: totalPages,
    sectionTitle: '§8. AI Code Review',
    content: [
      pw.Text('8.1. Quy trình Đánh giá Mã nguồn bằng AI (AI Code Review)',
          style: pw.TextStyle(font: fontBold, fontSize: 11, color: PdfColors.blue900)),
      pw.SizedBox(height: 6),
      pw.Text(
        'Tuân thủ mục §9 của Checklist Lab 3, nhóm đã tiến hành rà soát mã nguồn tự động thông qua công cụ phân tích tĩnh AI. '
        'Đã ghi nhận 5 phát hiện chính (findings) thuộc các nhóm: Đúng đắn (Correctness), Bảo mật (Security) và Tinh gọn (Simplification).',
        style: pw.TextStyle(font: fontRegular, fontSize: 8.5),
      ),
      pw.SizedBox(height: 6),
      pw.Table(
        border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
        children: [
          pw.TableRow(
            decoration: const pw.BoxDecoration(color: PdfColors.blue50),
            children: [
              pw.Padding(padding: const pw.EdgeInsets.all(3), child: pw.Text('ID', style: pw.TextStyle(font: fontBold, fontSize: 7.5))),
              pw.Padding(padding: const pw.EdgeInsets.all(3), child: pw.Text('Phát hiện (Finding Description)', style: pw.TextStyle(font: fontBold, fontSize: 7.5))),
              pw.Padding(padding: const pw.EdgeInsets.all(3), child: pw.Text('Nhóm', style: pw.TextStyle(font: fontBold, fontSize: 7.5))),
              pw.Padding(padding: const pw.EdgeInsets.all(3), child: pw.Text('Quyết định & Hành động sửa lỗi', style: pw.TextStyle(font: fontBold, fontSize: 7.5))),
            ],
          ),
          pw.TableRow(children: [
            pw.Padding(padding: const pw.EdgeInsets.all(3), child: pw.Text('CR-01', style: pw.TextStyle(font: fontBold, fontSize: 7.5))),
            pw.Padding(padding: const pw.EdgeInsets.all(3), child: pw.Text('Advisor thiếu 4 cấp tư vấn theo rubric, thiếu dialog xin quyền chia sẻ và thiếu cơ chế retry khi lỗi.', style: pw.TextStyle(font: fontRegular, fontSize: 7.5))),
            pw.Padding(padding: const pw.EdgeInsets.all(3), child: pw.Text('Functionality', style: pw.TextStyle(font: fontRegular, fontSize: 7.5))),
            pw.Padding(padding: const pw.EdgeInsets.all(3), child: pw.Text('ACCEPTED. Viết lại toàn bộ AdvisorViewModel và AdvisorScreen, bổ sung ChoiceChip 4 cấp và dialog _askConsent() fail-closed.', style: pw.TextStyle(font: fontRegular, fontSize: 7.5))),
          ]),
          pw.TableRow(children: [
            pw.Padding(padding: const pw.EdgeInsets.all(3), child: pw.Text('CR-02', style: pw.TextStyle(font: fontBold, fontSize: 7.5))),
            pw.Padding(padding: const pw.EdgeInsets.all(3), child: pw.Text('Firestore Timestamp parsing trong NoteModel gây crash khi reload ghi chú đã lưu từ Firebase.', style: pw.TextStyle(font: fontRegular, fontSize: 7.5))),
            pw.Padding(padding: const pw.EdgeInsets.all(3), child: pw.Text('Correctness', style: pw.TextStyle(font: fontRegular, fontSize: 7.5))),
            pw.Padding(padding: const pw.EdgeInsets.all(3), child: pw.Text('ACCEPTED. Sửa phương thức fromMap trong NoteModel hỗ trợ cả Timestamp và String ISO 8601.', style: pw.TextStyle(font: fontRegular, fontSize: 7.5))),
          ]),
          pw.TableRow(children: [
            pw.Padding(padding: const pw.EdgeInsets.all(3), child: pw.Text('CR-03', style: pw.TextStyle(font: fontBold, fontSize: 7.5))),
            pw.Padding(padding: const pw.EdgeInsets.all(3), child: pw.Text('Màn hình chi tiết môn học (CourseDetailScreen) hiển thị rỗng thay vì trạng thái loading/error chuẩn.', style: pw.TextStyle(font: fontRegular, fontSize: 7.5))),
            pw.Padding(padding: const pw.EdgeInsets.all(3), child: pw.Text('Architecture', style: pw.TextStyle(font: fontRegular, fontSize: 7.5))),
            pw.Padding(padding: const pw.EdgeInsets.all(3), child: pw.Text('ACCEPTED. Bổ sung đầy đủ 4 nhánh AsyncViewState (Loading, Error/Retry, Empty, Data) trước khi lookup.', style: pw.TextStyle(font: fontRegular, fontSize: 7.5))),
          ]),
          pw.TableRow(children: [
            pw.Padding(padding: const pw.EdgeInsets.all(3), child: pw.Text('CR-04', style: pw.TextStyle(font: fontBold, fontSize: 7.5))),
            pw.Padding(padding: const pw.EdgeInsets.all(3), child: pw.Text('Giao diện còn tồn tại màu hardcode (Color(0xFFB3261E)) và kích thước font/spacing không có token.', style: pw.TextStyle(font: fontRegular, fontSize: 7.5))),
            pw.Padding(padding: const pw.EdgeInsets.all(3), child: pw.Text('Design System', style: pw.TextStyle(font: fontRegular, fontSize: 7.5))),
            pw.Padding(padding: const pw.EdgeInsets.all(3), child: pw.Text('ACCEPTED. Thêm AppElevation, AppFontSize vào app_spacing.dart và thay thế toàn bộ mã màu lẻ tẻ bằng AppColors.*.', style: pw.TextStyle(font: fontRegular, fontSize: 7.5))),
          ]),
          pw.TableRow(children: [
            pw.Padding(padding: const pw.EdgeInsets.all(3), child: pw.Text('CR-05', style: pw.TextStyle(font: fontBold, fontSize: 7.5))),
            pw.Padding(padding: const pw.EdgeInsets.all(3), child: pw.Text('Logic so sánh version trong remote_config_service gắn liền với SDK, không thể test đơn vị độc lập.', style: pw.TextStyle(font: fontRegular, fontSize: 7.5))),
            pw.Padding(padding: const pw.EdgeInsets.all(3), child: pw.Text('Simplification', style: pw.TextStyle(font: fontRegular, fontSize: 7.5))),
            pw.Padding(padding: const pw.EdgeInsets.all(3), child: pw.Text('ACCEPTED. Tách hàm thuần Dart vào lib/utils/version_utils.dart và re-export cho 16 unit tests.', style: pw.TextStyle(font: fontRegular, fontSize: 7.5))),
          ]),
        ],
      ),
      pw.SizedBox(height: 10),
      pw.Text('8.2. Kế hoạch Tách Commit Sửa Lỗi theo Chuẩn Rubric',
          style: pw.TextStyle(font: fontBold, fontSize: 10, color: PdfColors.blue800)),
      pw.SizedBox(height: 4),
      pw.Text(
        'Rubric §9 yêu cầu sửa ít nhất 3 findings bằng 3 commit riêng biệt khi tạo Pull Request:\n'
        '1. `fix(CR-01)`: Tái cấu trúc Cố vấn học tập (Advisor 4 cấp, consent dialog, error retry).\n'
        '2. `fix(CR-02)`: Sửa lỗi phân giải Firestore Timestamp và tối ưu Task canonical ID.\n'
        '3. `fix(CR-04)`: Chuẩn hóa toàn bộ Design Tokens và thêm trợ năng Semantics.\n'
        '(Các commit này sẽ được thực hiện khi người dùng yêu cầu tạo nhánh PR công khai).',
        style: pw.TextStyle(font: fontRegular, fontSize: 8),
      ),
    ],
  ));

  // ----------------------------------------------------
  // TRANG 10: §9 CHALLENGES, LESSONS & TRACEABILITY
  // ----------------------------------------------------
  doc.addPage(createPage(
    pageNum: 10,
    totalPages: totalPages,
    sectionTitle: '§9. Challenges & Traceability',
    content: [
      pw.Text('9.1. Khó khăn kỹ thuật & Bài học kinh nghiệm',
          style: pw.TextStyle(font: fontBold, fontSize: 11, color: PdfColors.blue900)),
      pw.SizedBox(height: 6),
      pw.Bullet(text: 'Sự cố ghi đè Task Canonical ID (BUG-01): Khi cập nhật task, toán tử spread của Dart đã vô tình ghi đè ID tài liệu Firestore bằng id rỗng. Bài học: Luôn kiểm tra tính bất biến của khóa chính trong tầng Repository.', style: pw.TextStyle(font: fontRegular, fontSize: 8)),
      pw.Bullet(text: 'Khác biệt kiểu dữ liệu Timestamp (BUG-02): Firestore SDK trả về đối tượng Timestamp trong khi local cache dùng String ISO-8601. Bài học: Thiết kế fromMap linh hoạt, kiểm tra kiểu động trước khi ép kiểu DateTime.', style: pw.TextStyle(font: fontRegular, fontSize: 8)),
      pw.Bullet(text: 'Giới hạn gói cước Spark & Quota AI: Việc sử dụng Gemini Free Tier dẫn đến tình trạng chạm hạn ngạch 20 requests/ngày khi chạy E2E. Bài học: Cần có phương án fallback qua mock hoặc nâng cấp gói cước khi bước vào giai đoạn kiểm thử cao điểm.', style: pw.TextStyle(font: fontRegular, fontSize: 8)),
      pw.SizedBox(height: 10),
      pw.Text('9.2. Bảng Truy vết Bằng chứng Nộp bài (Evidence Traceability)',
          style: pw.TextStyle(font: fontBold, fontSize: 10, color: PdfColors.blue800)),
      pw.SizedBox(height: 4),
      pw.Table(
        border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
        children: [
          pw.TableRow(
            decoration: const pw.BoxDecoration(color: PdfColors.blue50),
            children: [
              pw.Padding(padding: const pw.EdgeInsets.all(3), child: pw.Text('Hạng mục', style: pw.TextStyle(font: fontBold, fontSize: 7.5))),
              pw.Padding(padding: const pw.EdgeInsets.all(3), child: pw.Text('Yêu cầu Rubric', style: pw.TextStyle(font: fontBold, fontSize: 7.5))),
              pw.Padding(padding: const pw.EdgeInsets.all(3), child: pw.Text('Đường dẫn bằng chứng trong repo', style: pw.TextStyle(font: fontBold, fontSize: 7.5))),
              pw.Padding(padding: const pw.EdgeInsets.all(3), child: pw.Text('Trạng thái', style: pw.TextStyle(font: fontBold, fontSize: 7.5))),
            ],
          ),
          pw.TableRow(children: [
            pw.Padding(padding: const pw.EdgeInsets.all(3), child: pw.Text('Mã nguồn Flutter', style: pw.TextStyle(font: fontRegular, fontSize: 7.5))),
            pw.Padding(padding: const pw.EdgeInsets.all(3), child: pw.Text('MVVM, Tokens, 11 screens', style: pw.TextStyle(font: fontRegular, fontSize: 7.5))),
            pw.Padding(padding: const pw.EdgeInsets.all(3), child: pw.Text('lib/ (theme, models, services, screens...)', style: pw.TextStyle(font: fontRegular, fontSize: 7.5))),
            pw.Padding(padding: const pw.EdgeInsets.all(3), child: pw.Text('SẴN SÀNG', style: pw.TextStyle(font: fontBold, fontSize: 7.5, color: PdfColors.green800))),
          ]),
          pw.TableRow(children: [
            pw.Padding(padding: const pw.EdgeInsets.all(3), child: pw.Text('Kiểm thử nội bộ', style: pw.TextStyle(font: fontRegular, fontSize: 7.5))),
            pw.Padding(padding: const pw.EdgeInsets.all(3), child: pw.Text('Analyze 0 lỗi, Test 89/89, APK', style: pw.TextStyle(font: fontRegular, fontSize: 7.5))),
            pw.Padding(padding: const pw.EdgeInsets.all(3), child: pw.Text('test/ (89 tests), build/app-debug.apk', style: pw.TextStyle(font: fontRegular, fontSize: 7.5))),
            pw.Padding(padding: const pw.EdgeInsets.all(3), child: pw.Text('SẴN SÀNG', style: pw.TextStyle(font: fontBold, fontSize: 7.5, color: PdfColors.green800))),
          ]),
          pw.TableRow(children: [
            pw.Padding(padding: const pw.EdgeInsets.all(3), child: pw.Text('Báo cáo & Slide', style: pw.TextStyle(font: fontRegular, fontSize: 7.5))),
            pw.Padding(padding: const pw.EdgeInsets.all(3), child: pw.Text('Report 8-12 trang, Slide 12-15 tr', style: pw.TextStyle(font: fontRegular, fontSize: 7.5))),
            pw.Padding(padding: const pw.EdgeInsets.all(3), child: pw.Text('report/Lab03_[StudentID].pdf, slides/...', style: pw.TextStyle(font: fontRegular, fontSize: 7.5))),
            pw.Padding(padding: const pw.EdgeInsets.all(3), child: pw.Text('ĐÃ KẾT XUẤT', style: pw.TextStyle(font: fontBold, fontSize: 7.5, color: PdfColors.green800))),
          ]),
          pw.TableRow(children: [
            pw.Padding(padding: const pw.EdgeInsets.all(3), child: pw.Text('Firebase Console', style: pw.TextStyle(font: fontRegular, fontSize: 7.5))),
            pw.Padding(padding: const pw.EdgeInsets.all(3), child: pw.Text('Ảnh chụp Auth, Firestore, DebugView', style: pw.TextStyle(font: fontRegular, fontSize: 7.5))),
            pw.Padding(padding: const pw.EdgeInsets.all(3), child: pw.Text('evidence/firebase/* (chờ chụp thực tế)', style: pw.TextStyle(font: fontRegular, fontSize: 7.5))),
            pw.Padding(padding: const pw.EdgeInsets.all(3), child: pw.Text('CHỜ THIẾT BỊ', style: pw.TextStyle(font: fontBold, fontSize: 7.5, color: PdfColors.orange800))),
          ]),
          pw.TableRow(children: [
            pw.Padding(padding: const pw.EdgeInsets.all(3), child: pw.Text('ARTEMIS E2E', style: pw.TextStyle(font: fontRegular, fontSize: 7.5))),
            pw.Padding(padding: const pw.EdgeInsets.all(3), child: pw.Text('Tối thiểu 10 ca × 3 lượt chạy', style: pw.TextStyle(font: fontRegular, fontSize: 7.5))),
            pw.Padding(padding: const pw.EdgeInsets.all(3), child: pw.Text('evidence/artemis/RUN_LOG_2026-11-04.md', style: pw.TextStyle(font: fontRegular, fontSize: 7.5))),
            pw.Padding(padding: const pw.EdgeInsets.all(3), child: pw.Text('CHỜ QUOTA', style: pw.TextStyle(font: fontBold, fontSize: 7.5, color: PdfColors.red800))),
          ]),
          pw.TableRow(children: [
            pw.Padding(padding: const pw.EdgeInsets.all(3), child: pw.Text('Video Demo', style: pw.TextStyle(font: fontRegular, fontSize: 7.5))),
            pw.Padding(padding: const pw.EdgeInsets.all(3), child: pw.Text('5–10 phút có tiếng và thuyết minh', style: pw.TextStyle(font: fontRegular, fontSize: 7.5))),
            pw.Padding(padding: const pw.EdgeInsets.all(3), child: pw.Text('docs/lab3-video-script.md (chờ quay)', style: pw.TextStyle(font: fontRegular, fontSize: 7.5))),
            pw.Padding(padding: const pw.EdgeInsets.all(3), child: pw.Text('CHỜ QUAY', style: pw.TextStyle(font: fontBold, fontSize: 7.5, color: PdfColors.orange800))),
          ]),
        ],
      ),
      pw.SizedBox(height: 10),
      pw.Text('9.3. Kết luận về Mức độ Sẵn sàng Nộp bài',
          style: pw.TextStyle(font: fontBold, fontSize: 10, color: PdfColors.blue800)),
      pw.SizedBox(height: 4),
      pw.Text(
        'Dự án đạt 100% về mặt hoàn thiện mã nguồn và kiểm thử đơn vị nội bộ. '
        'Hồ sơ sẽ hoàn tất 100% ngay khi bổ sung Student ID, thực hiện đợt chạy ARTEMIS sau khi phục hồi quota, '
        'chụp màn hình xác thực Firebase Console và hoàn thành video demo theo kịch bản có sẵn.',
        style: pw.TextStyle(font: fontRegular, fontSize: 8),
      ),
    ],
  ));

  // Lưu file PDF
  final bytes = await doc.save();
  final outDir = Directory('report');
  if (!outDir.existsSync()) outDir.createSync(recursive: true);

  final outFile = File('report/Lab03_STUDENT_ID.pdf');
  await outFile.writeAsBytes(bytes);

  print('Successfully generated Report PDF: ${outFile.path}');
  print('Total pages: ${doc.document.pdfPageList.pages.length} (Target: 8-12 pages)');
}
