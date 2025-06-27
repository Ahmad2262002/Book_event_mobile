import "package:get/get.dart";

import "../Controllers/AdminHomeController.dart";

class AdminHomeBinding extends Bindings {
  @override
  void dependencies() {
    // TODO: implement dependencies
    Get.lazyPut(() => AdminHomeController());
  }
}
