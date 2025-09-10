import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class FirebaseServices {
  final auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  final googleSignIn = GoogleSignIn();

  // Login bằng email & password
  Future<User?> signInWithEmail(String email, String password) async {
    final credential = await auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    return credential.user;
  }

  Future<User?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleSignInAccount =
      await googleSignIn.signIn();
      if (googleSignInAccount == null) return null; // user cancel

      final GoogleSignInAuthentication googleSignInAuthentication =
      await googleSignInAccount.authentication;
      final AuthCredential authCredential = GoogleAuthProvider.credential(
        accessToken: googleSignInAuthentication.accessToken,
        idToken: googleSignInAuthentication.idToken,
      );
      UserCredential userCredential = await auth.signInWithCredential(authCredential);
      User? user = userCredential.user;

      if (user != null) {
        await saveUserToFirestore(user);
      }
      return user;
    } on FirebaseAuthException catch (e) {
      print("FirebaseAuthException: ${e.message}");
      return null;
    } catch (e) {
      print("Google SignIn error: $e");
      return null;
    }
  }


  Future<void> googleSignOut() async {
    await googleSignIn.signOut();
    // await auth.signOut();
  }

  Future<void> saveUserToFirestore(User user) async {
    DocumentSnapshot documentSnapshot = await _firestore.collection('account').doc(user.uid).get();

    if(!documentSnapshot.exists){
      await _firestore.collection('account').doc(user.uid).set({
        'name': user.displayName,
        'email': user.email,
        'uid': user.uid,
        'phone': '',
        'address': '',
        'online': false,
        'image': user.photoURL,
        'role': 'user',
      });
    }
  }
}
