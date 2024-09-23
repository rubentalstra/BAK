import 'package:bak_tracker/bloc/association/association_bloc.dart';
import 'package:bak_tracker/bloc/association/association_event.dart';
import 'package:bak_tracker/core/themes/colors.dart';
import 'package:bak_tracker/ui/home/main_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:bak_tracker/services/join_association_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class InviteCodeInputWidget extends StatefulWidget {
  const InviteCodeInputWidget({super.key});

  @override
  _InviteCodeInputWidgetState createState() => _InviteCodeInputWidgetState();
}

class _InviteCodeInputWidgetState extends State<InviteCodeInputWidget> {
  final List<TextEditingController> _controllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  String? _errorMessage;
  bool _isSubmitting = false;

  final JoinAssociationService _joinAssociationService =
      JoinAssociationService();

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  // Method to handle submission when code is fully entered
  Future<void> _submitCode(BuildContext context) async {
    final inviteCode = _controllers.map((e) => e.text).join();
    if (inviteCode.length == 6) {
      setState(() {
        _isSubmitting = true; // Show loading state
        _errorMessage = null; // Clear previous error message
      });

      try {
        final newAssociation =
            await _joinAssociationService.joinAssociation(inviteCode);

        // Dispatch event to update state with the new association
        context
            .read<AssociationBloc>()
            .add(JoinNewAssociation(newAssociation: newAssociation));

        // Navigate to MainScreen and remove all previous routes
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const MainScreen()),
          (Route<dynamic> route) => false, // Remove all routes from the stack
        );
      } catch (error) {
        setState(() {
          _isSubmitting = false;
          _errorMessage = error.toString();
        });
      }
    } else {
      setState(() {
        _errorMessage = 'Please enter all 6 characters.';
      });
    }
  }

  // Method to handle paste action
  void _handlePaste(String pastedText) {
    if (pastedText.length == 6) {
      for (int i = 0; i < 6; i++) {
        _controllers[i].text = pastedText[i]; // Set each character
      }
      FocusScope.of(context).unfocus(); // Unfocus all text fields after paste
      _submitCode(context); // Submit the code automatically after pasting
    } else {
      setState(() {
        _errorMessage = 'The code must be exactly 6 characters long.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Enter 6-Digit Invitation Code',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.lightPrimary),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(6, (index) {
                return _buildCodeField(index);
              }),
            ),
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.red, fontSize: 14),
                ),
              ),
            const SizedBox(height: 20),
            _isSubmitting
                ? const CircularProgressIndicator() // Show a loading indicator while submitting
                : ElevatedButton(
                    onPressed: () => _submitCode(context),
                    child: const Text('Join Association'),
                  ),
          ],
        ),
      ),
    );
  }

// Method to build each individual text field
  Widget _buildCodeField(int index) {
    return SizedBox(
      width: 40, // Fixed width for each code box
      child: TextField(
        controller: _controllers[index],
        focusNode: _focusNodes[index],
        textAlign: TextAlign.center,
        maxLength: 1, // Limit to 1 character per field
        textCapitalization:
            TextCapitalization.characters, // Auto capitalize letters
        style: const TextStyle(
          color: AppColors.lightPrimary, // Set the text color to primary
          fontWeight: FontWeight.bold, // Optionally make the text bold
          fontSize: 18, // Adjust font size for better visibility
        ),
        decoration: InputDecoration(
          counterText: '', // Hide the character counter
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8), // Rounded corners
          ),
          hoverColor: AppColors.lightPrimary,
          focusedBorder: OutlineInputBorder(
            borderSide: const BorderSide(
              color: AppColors.lightPrimary, // Border color when focused
              width: 2.0,
            ),
            borderRadius: BorderRadius.circular(8), // Rounded corners
          ),
          enabledBorder: OutlineInputBorder(
            borderSide: const BorderSide(
              color: AppColors.lightPrimary, // Border color when not focused
              width: 1.5,
            ),
            borderRadius: BorderRadius.circular(8), // Rounded corners
          ),
        ),
        keyboardType: TextInputType.text,
        textInputAction:
            index < 5 ? TextInputAction.next : TextInputAction.done,
        onChanged: (value) {
          if (value.isNotEmpty) {
            if (index < 5) {
              FocusScope.of(context).requestFocus(
                  _focusNodes[index + 1]); // Move focus to next field
            } else {
              _submitCode(context); // Last field, submit the code
            }
          }
        },
        onSubmitted: (value) {
          if (index == 5) {
            _submitCode(context);
          }
        },
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(
              r'[A-Z0-9]')), // Only uppercase letters and numbers allowed
          LengthLimitingTextInputFormatter(1), // Only 1 char allowed
          TextInputFormatter.withFunction(
            (oldValue, newValue) {
              if (newValue.text.length > 1) {
                _handlePaste(newValue.text); // Handle pasted text
                return oldValue; // Prevents multiple characters in the field
              }
              return newValue;
            },
          ),
        ],
      ),
    );
  }
}
