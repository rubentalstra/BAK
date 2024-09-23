import 'package:bak_tracker/bloc/association/association_event.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:bak_tracker/services/join_association_service.dart';
import 'package:bak_tracker/core/themes/colors.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bak_tracker/bloc/association/association_bloc.dart';
import 'package:bak_tracker/ui/home/main_screen.dart';

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

  Future<void> _submitCode(BuildContext context) async {
    final inviteCode = _controllers.map((e) => e.text).join();
    if (inviteCode.length == 6) {
      setState(() {
        _isSubmitting = true;
        _errorMessage = null;
      });

      try {
        final newAssociation =
            await _joinAssociationService.joinAssociation(inviteCode);

        context
            .read<AssociationBloc>()
            .add(JoinNewAssociation(newAssociation: newAssociation));

        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const MainScreen()),
          (Route<dynamic> route) => false,
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

  void _handlePaste(String pastedText) {
    if (pastedText.length == 6) {
      for (int i = 0; i < 6; i++) {
        _controllers[i].text = pastedText[i];
      }
      FocusScope.of(context).unfocus();
      _submitCode(context);
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
                color: AppColors.lightPrimary,
              ),
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
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: () => _submitCode(context),
                    child: const Text('Join Association'),
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildCodeField(int index) {
    return SizedBox(
      width: 40,
      child: TextField(
        controller: _controllers[index],
        focusNode: _focusNodes[index],
        textAlign: TextAlign.center,
        maxLength: 1,
        textCapitalization: TextCapitalization.characters,
        style: const TextStyle(
          color: AppColors.lightPrimary,
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
        decoration: InputDecoration(
          counterText: '',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: const BorderSide(
              color: AppColors.lightPrimary,
              width: 2.0,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          enabledBorder: OutlineInputBorder(
            borderSide: const BorderSide(
              color: AppColors.lightPrimary,
              width: 1.5,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        keyboardType: TextInputType.text,
        textInputAction:
            index < 5 ? TextInputAction.next : TextInputAction.done,
        onChanged: (value) {
          if (value.isNotEmpty && index < 5) {
            FocusScope.of(context).requestFocus(_focusNodes[index + 1]);
          } else if (index == 5) {
            _submitCode(context);
          }
        },
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'[A-Z0-9]')),
          LengthLimitingTextInputFormatter(1),
          TextInputFormatter.withFunction(
            (oldValue, newValue) {
              if (newValue.text.length > 1) {
                _handlePaste(newValue.text);
                return oldValue;
              }
              return newValue;
            },
          ),
        ],
      ),
    );
  }
}
