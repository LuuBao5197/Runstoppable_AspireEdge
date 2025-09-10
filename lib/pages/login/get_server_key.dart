import 'package:googleapis_auth/auth_io.dart';

class GetServerKey {
  Future<String> getServerKeyToken() async {
    final scopes = [
      'https://www.googleapis.com/auth/userinfo.email',
      'https://www.googleapis.com/auth/firebase.database',
      'https://www.googleapis.com/auth/firebase.messaging',
    ];

    final client = await clientViaServiceAccount(
        ServiceAccountCredentials.fromJson({
          "type": "service_account",
          "project_id": "aspire-edge-app",
          "private_key_id": "0e8797be4b08fa3cc963ed191ad60c762f28b28e",
          "private_key": "-----BEGIN PRIVATE KEY-----\nMIIEvgIBADANBgkqhkiG9w0BAQEFAASCBKgwggSkAgEAAoIBAQCy+m5jBhUstle5\nR2/M9kQ8EzAg6gUArwxrfXQFIBpnVsrnhSa9RN8D1Y0rTMP+JgrZnHn0LDP8w/gc\npUsc/WSsbIWAleca/LSYxqLYmmNe8xI6Sdu5nOYgayiUmJkKIlE891D+QYcATpx6\nlaLqcvmbggwWkrT4w5fxfI/46sqI2eVuMcSA7mb2DSGmWvJ9HuLTxheuvisAJT71\nb/Ba/h1GNiOY5akyRDGQN0++2weMaak6Wq3CeBjw7c/5UUep+WkZGrQDC/Ulgcm2\ns7eFRl18jhVPD0jngYd1GfAJcy9nHSZs9poGgNT0xJUFOmHdiLDlJPGYjzmDC78E\nsrNpWtmdAgMBAAECggEABQ/w8rC9BUBnEiDYzbBNf8bUfqnVLblwctM1O+E2Pflb\ney7t8z6GcaJRqt7cpaHyfp3evoRIOCcG1oXqWPiQfLwDuVOuxLmka18lmKt352Xy\npwlobe3n0xTqLJcgWllcI4r56dHKqBHmenp5sC3uV3KsitroGX0sHV12PlvNvLnO\nPVSG7ILkeNr5RGplA5hWRe4WVqnunCw7W4NIgXpgPFmi6or+UYnvCloRGS1z8kL4\n6msLKy7HAlOs+6Kwn9XJZoMFE8P8+R8oL13xmomnr+DW0/TMPEQo+Ou0oC9CigKm\nH2CFpKXy2w6s+RqgUVL6PcV1rj1LOOv4Re1ECmnX1QKBgQDi7FQgRASJN/TTqt9w\n2XDiTclzLeq1IhE+p+XY3ASGjAxyTlRgvfZzwjUc7//QaLsRh3LyrBbCv58nRK+h\n/KDvkG7EwMA6gTYW+2er+R0UWgJCG6r4/VOnDz2nG4/9OB0yuv8gZDUmWQ08XaKy\nKaXlJ/BI/7UnBzzgjWAokLDsBwKBgQDJ6WJqx/bZria+HZhPmdNmi7zNGCa+6Q5n\nXT2r2nZty0JsKwvNDag2SNxjP7/yFJgC0GtPPhHant4nKp40Z6NXSeoAF2HcpXmB\nrZteBYUAjmziVBUPRd9DFeV2YX8zTBFhfBvizNeaxDMVeWH/WZIcVbbrwesiJtjg\nsKdMDZLsOwKBgQC6+PysBT8zjM6GZUFr602uuWcmJww/qM1Kse6Zi1eTQOu0d0Pg\n3kSlxrwalslSACk63T7iItcyKc9J/Lc2IkC8g2YxaZw52GMn9ofKVB0Yur0nmUJ7\nm8eEW/NxsC0o+EZemWNDXi3I5hEYzxIR+Gz/brP2gfLSMI2BfBth8S5FmwKBgBcY\nIrGj/ZAYY0YLjIhOR+fKw+WRhZ0Aey1HdO5bJoCYZxiIM+lYTo0m+E5B1GqUAG8R\n97QwnUosMay5Ky9DS2OIiMNJ6V+bbbJvcP3oE7Zkk/+vLll43HiH4J8Rt8LeSH6l\n+2qNk3uYRV+HarYSQKwNAcclfweA+f15NylzxAJRAoGBAKkbkXFlk/AVQtQ69eY8\noK9SJvr5pDSJbEktOioipIucM4l6gJ3EBFHBctLd7kfVKJXCiZQJO4JNYypVc9Gn\nNa8JRUr/D6/uEpRgAgJo/5x/YAaZJmyMeAQxdVsBy5oUaMBIEEuuP+Mwq1TLZmx2\nrDVXZdprRFk0EPulNiU2RZ5+\n-----END PRIVATE KEY-----\n",
          "client_email": "firebase-adminsdk-fbsvc@aspire-edge-app.iam.gserviceaccount.com",
          "client_id": "111634712414746583589",
          "auth_uri": "https://accounts.google.com/o/oauth2/auth",
          "token_uri": "https://oauth2.googleapis.com/token",
          "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
          "client_x509_cert_url": "https://www.googleapis.com/robot/v1/metadata/x509/firebase-adminsdk-fbsvc%40aspire-edge-app.iam.gserviceaccount.com",
          "universe_domain": "googleapis.com"
        }),
        scopes);
    final accessServerKey = client.credentials.accessToken.data;
    return accessServerKey;
  }
}
