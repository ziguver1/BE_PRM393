import 'package:flutter/material.dart';

class AddressBookScreen extends StatelessWidget {
  const AddressBookScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Addresses'),
      ),
      body: const Center(
        child: Text('Address Book Screen'),
      ),
    );
  }
}
