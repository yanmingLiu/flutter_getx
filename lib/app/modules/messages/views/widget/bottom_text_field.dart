import 'package:flutter/material.dart';

class BottomTextField extends StatefulWidget {
  final Function onSubmitted;

  const BottomTextField({super.key, required this.onSubmitted});

  @override
  createState() => _BottomTextFieldState();
}

class _BottomTextFieldState extends State<BottomTextField> {
  final _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  // double _bottomPadding = 0;

  @override
  void initState() {
    super.initState();
    // Add a delay to ensure TextField gets focus after it's shown
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 25),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: TextField(
            focusNode: _focusNode,
            controller: _textController,
            decoration: const InputDecoration(
              hintText: 'Type something...',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(vertical: 10.0),
            ),
            // onTap: () {
            //   _setBottomPadding(context);
            // },
            onSubmitted: (value) {
              widget.onSubmitted(); // Trigger the submitted function provided in the constructor
            },
          ),
        ),
      ),
    );
  }

  // void _setBottomPadding(BuildContext context) {
  //   final viewInsetsBottom = MediaQuery.of(context).viewInsets.bottom;
  //   if (viewInsetsBottom > 0) {
  //     setState(() {
  //       _bottomPadding = viewInsetsBottom;
  //     });
  //   }
  // }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }
}
