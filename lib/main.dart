// ignore_for_file: must_be_immutable

import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:http/http.dart' as http;

void main() async {
  await dotenv.load(fileName: '.env'); // Load environment variables

  Stripe.publishableKey = dotenv.env['STRIPE_PUBLISHABLE_KEY']!;

  runApp(const MainApp());
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  Map<String, dynamic>? paymentIntent;

  String amount = "0";

  @override
  void initState() {
    super.initState();
  }

  void setAmount(String newAmount) {
    setState(() {
      amount = newAmount;
    });
  }

  void displayPaymentSheet() async {
    // This method displays a payment sheet created in the flutter stripe SDK
    try {
      await Stripe.instance.presentPaymentSheet();
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  createPaymentIntent() async {
    ///This method creates the required payment
    try {
      Map<String, String> body = {
        'amount': amount.toString(),
        'currency': 'USD',
      };

      http.Response response = await http.post(
          Uri.parse('https://api.stripe.com/v1/payment_intents'),
          body: body,
          headers: {
            "Authorization": "Bearer ${dotenv.env['STRIPE_SECRET_KEY']!}",
            // "Content-Type": "application/json"
          });

      return jsonDecode(response.body);
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  void makePayment() async {
    //This method displays the payment sheet with the required payment

    try {
      //Here we are creating are payment
      paymentIntent = await createPaymentIntent();

      log(paymentIntent.toString());

      var gpay = const PaymentSheetGooglePay(
        merchantCountryCode: 'US',
        currencyCode: 'USD',
        testEnv: true,
      );

      await Stripe.instance.initPaymentSheet(
          paymentSheetParameters: SetupPaymentSheetParameters(
        paymentIntentClientSecret: paymentIntent!['client_secret'],
        googlePay: gpay,
        merchantDisplayName: 'Nikola',
        style: ThemeMode.dark,
      ));

      //Here we are desplaying our created payment sheet
      displayPaymentSheet();
    } catch (e) {
      throw Exception(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextFormField(
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    setAmount(value);
                  },
                ),
                const SizedBox(
                  height: 20,
                ),
                TextButton(
                    onPressed: () {
                      makePayment();
                    },
                    child: const Text('Pay me')),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
