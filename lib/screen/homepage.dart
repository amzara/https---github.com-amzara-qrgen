import 'package:flutter/material.dart';
import 'mergeSingle.dart';
import 'mergeRange.dart';
import 'mergeTarget.dart';
import 'function4.dart';

import 'package:material_symbols_icons/material_symbols_icons.dart';

class homepage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Theme(
        data: ThemeData.dark(),
        child: Scaffold(
          body: SingleChildScrollView(
            padding: EdgeInsets.only(bottom: 0.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Adjust the space above the image
                Container(
                  child: Center(
                    child: Image.asset(
                      'assets/images/123logo.png',
                      height: 200,
                    ),
                  ),
                ),
                // Buttons
                _buildButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => mergeSingle(),
                      ),
                    );
                  },
                  icon: Symbols.qr_code_2,
                  text: 'Generate Single QR',
                ),
                _buildButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => mergeRange(),
                      ),
                    );
                  },
                  icon: Symbols.arrow_range,
                  text: 'Generate QR Range',
                ),
                _buildButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => mergeTarget(),
                      ),
                    );
                  },
                  icon: Symbols.qr_code_2_add,
                  text: 'Generate Multiple QR',
                ),
                _buildButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => function4(),
                      ),
                    );
                  },
                  icon: Symbols.csv,
                  text: 'Generate from CSV',
                ),
              ],
            ),
          ),
        ));
  }

  Widget _buildButton(
      {required VoidCallback onPressed,
      required IconData icon,
      required String text}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5.0),
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.purple, width: 2),
            ),
            child: RawMaterialButton(
              onPressed: onPressed,
              elevation: 2.0,
              fillColor: Colors.white,
              child: Icon(
                icon,
                size: 30.0,
                color: Colors.black,
              ),
              padding: EdgeInsets.all(15.0),
              shape: CircleBorder(),
            ),
          ),
          SizedBox(height: 8),
          Text(
            text,
            style: TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }
}
