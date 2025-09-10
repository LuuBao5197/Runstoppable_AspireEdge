import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthServices {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<String> signUpUser({required String name, required String email, required String password, required String phone, required String address}) async{
    String res = 'Something went wrong';
    try{
      if(name.isNotEmpty || email.isNotEmpty || password.isNotEmpty || phone.isNotEmpty){
        UserCredential credential = await _auth.createUserWithEmailAndPassword(email: email, password: password);
        await _firestore.collection('account').doc(credential.user!.uid).set({
          'name': name,
          'email': email,
          'phone': phone,
          'address': address,
          'image': '',
          'role': 'user',
          'online': false,
          'uid': credential.user!.uid,
        });
        res = 'Successfully';
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        res = 'Email đã tồn tại';
      } else if (e.code == 'weak-password') {
        res = 'Mật khẩu quá yếu';
      } else {
        res = 'Lỗi: ${e.message}';
      }
    } catch (e, stack) {
      print("SignUp Error: $e");
      print(stack);
      res = 'Lỗi không xác định: $e';
    }
    return res;
  }

  // Future<String> signUpDriver({required String name, required String email, required String password, required String phone, required String address}) async{
  //   String res = 'Something went wrong';
  //   try{
  //     if(name.isNotEmpty || email.isNotEmpty || password.isNotEmpty || phone.isNotEmpty){
  //       UserCredential credential = await _auth.createUserWithEmailAndPassword(email: email, password: password);
  //       await _firestore.collection('driver').doc(credential.user!.uid).set({
  //         'name': name,
  //         'email': email,
  //         'phone': phone,
  //         'address': address,
  //         'image': '',
  //         'role': 'driver',
  //         'enable': 0,
  //         'status': 0,
  //         'online': false,
  //         'fcm_token': "",
  //         'uid': credential.user!.uid,
  //       });
  //       res = 'Successfully';
  //     }
  //   } catch (e) {
  //     res = e.toString();
  //   }
  //   return res;
  // }

  Future<dynamic> loginUser({required String email, required String password}) async{
    try{
        var loggedUser = await _auth.signInWithEmailAndPassword(email: email, password: password);
        // res = 'Successfully';
      return loggedUser;
    } catch (e) {
      print(e.toString());
      return null;
    }
  }

  Future<void> logout() async {
    try {
      // Sign out Firebase
      await _auth.signOut();

      // Sign out Google (nếu có)
      final googleSignIn = GoogleSignIn();
      if (await googleSignIn.isSignedIn()) {
        await googleSignIn.signOut();
      }
    } catch (e) {
      print("Logout error: $e");
    }
  }

}