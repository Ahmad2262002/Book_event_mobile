import 'package:get/get.dart';
import 'package:book_event/Bindings/LoginBinding.dart';
import 'package:book_event/Bindings/RegistrationBinding.dart';
import 'package:book_event/Routes/AppRoute.dart';

import '../Bindings/AdminHomeBinding.dart';
import '../Bindings/HomeBinding.dart';
import '../Views/AdminHome.dart';
import '../Views/Home.dart';
import '../Views/Login.dart';
import '../Views/Registration.dart';

class AppPage {
  static const String initial = AppRoute.initial;

  static final List<GetPage> pages = [
    GetPage(
      name: AppRoute.initial,  // This is now your login page
      page: () => Login(),
      binding: LoginBinding(),
    ),
    GetPage(
      name: AppRoute.register,
      page: () => Registration(),
      binding: RegistrationBinding(),
    ),
    // GetPage(
    //   name: AppRoute.home,
    //   page: () => Home(),
    //   binding: HomeBinding(),
    // ),
    GetPage(
      name: AppRoute.AminHome,
      page: () => AdminHome(),
      binding: AdminHomeBinding(),
    ),
  ];
}