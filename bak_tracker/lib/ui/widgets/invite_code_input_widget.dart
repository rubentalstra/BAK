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

  Future<void> _submitCode() async {
    final inviteCode = _controllers.map((e) => e.text.toUpperCase()).join();

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

  Future<void> _pasteCode() async {
    final clipboardContent = await Clipboard.getData('text/plain');

    if (clipboardContent?.text != null && clipboardContent!.text!.length == 6) {
      _handlePaste(clipboardContent.text!);
    } else {
      setState(() {
        _errorMessage = 'Clipboard must contain a 6-character code.';
      });
    }
  }

  void _handlePaste(String pastedText) {
    if (pastedText.length == 6) {
      for (int i = 0; i < 6; i++) {
        _controllers[i].text = pastedText[i].toUpperCase();
      }
      FocusScope.of(context).unfocus();
      _submitCode();
    } else {
      setState(() {
        _errorMessage = 'The code must be exactly 6 characters long.';
      });
    }
  }

  void _onCodeInputChanged(String value, int index) {
    if (value.isNotEmpty && index < 5) {
      FocusScope.of(context).requestFocus(_focusNodes[index + 1]);
    } else if (value.isEmpty && index > 0) {
      FocusScope.of(context).requestFocus(_focusNodes[index - 1]);
    } else if (index == 5 && value.isNotEmpty) {
      _submitCode();
    }
  }

  void _handleBackspaceKeyPress(KeyEvent event, int index) {
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.backspace) {
      if (_controllers[index].text.isEmpty && index > 0) {
        FocusScope.of(context).requestFocus(_focusNodes[index - 1]);
      }
    }
  }

  Widget _buildCodeField(int index) {
    return Flexible(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4.0),
        child: KeyboardListener(
          focusNode: FocusNode(),
          onKeyEvent: (event) => _handleBackspaceKeyPress(event, index),
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
            onChanged: (value) => _onCodeInputChanged(value, index),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
              LengthLimitingTextInputFormatter(1),
              TextInputFormatter.withFunction((oldValue, newValue) {
                return newValue.copyWith(
                  text: newValue.text.toUpperCase(),
                );
              }),
            ],
          ),
        ),
      ),
    );
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
              children: [
                Expanded(
                  child: Row(
                    children: List.generate(6, (index) {
                      return _buildCodeField(index);
                    }),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.paste),
                  color: AppColors.lightPrimary,
                  onPressed: _pasteCode,
                ),
              ],
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
                    onPressed: _submitCode,
                    child: const Text('Join Association'),
                  ),
          ],
        ),
      ),
    );
  }
}
