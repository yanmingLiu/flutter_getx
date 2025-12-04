import 'package:flutter/material.dart';

class BottomTextField extends StatefulWidget {
  final ValueChanged<String>? onTapSend;

  const BottomTextField({super.key, required this.onTapSend});

  @override
  createState() => _BottomTextFieldState();
}

class _BottomTextFieldState extends State<BottomTextField> {
  final _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  double _bottomPadding = 0;
  bool _sendButtonEnabled = false;

  @override
  void initState() {
    super.initState();
    // Add a delay to ensure TextField gets focus after it's shown
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });

    _focusNode.addListener(() {
      if (!_focusNode.hasFocus) {
        setState(() {
          FocusScope.of(context).unfocus();
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        GestureDetector(
          onTap: () {
            FocusScope.of(context).unfocus();
          },
          child: SingleChildScrollView(
            child: Column(
              children: <Widget>[
                // Your other widgets can be added here
                Container(
                  color: Colors.transparent,
                  height: 1000,
                ),
              ],
            ),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 25),
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: GestureDetector(
              onTap: () {},
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.max,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(12, 0, 12, 0),
                        decoration: const BoxDecoration(
                          color: Color(0xffE4E8F2),
                          borderRadius: BorderRadius.all(Radius.circular(20)),
                        ),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(
                            maxHeight: 36.0 * 2, // 设置最大高度为3行的高度
                          ),
                          child: TextField(
                            focusNode: _focusNode,
                            controller: _textController,
                            textInputAction: TextInputAction.done,
                            onChanged: (value) {
                              setState(() {
                                _sendButtonEnabled = value.isNotEmpty;
                              });
                            },
                            onSubmitted: (value) {
                              if (_textController.text.trim().isEmpty) {
                                // TODO: this
                                return;
                              }

                              if (widget.onTapSend != null) {
                                widget.onTapSend!(_textController.text.trim());
                              }
                            },
                            maxLines: null,
                            style: const TextStyle(
                              color: Color(0xff091326),
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                            ),
                            decoration: const InputDecoration(
                              // TODO:~翻译
                              hintText: 'Say hello...',
                              contentPadding: EdgeInsets.zero,
                              hintStyle: TextStyle(
                                color: Color(0xffA3A4AD),
                                fontSize: 12,
                                fontWeight: FontWeight.w400,
                              ),
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 20),
                    SizedBox(
                      width: 32,
                      height: 32,
                      child: IconButton(
                          onPressed: () {
                            // TODO: this
                          },
                          style: IconButton.styleFrom(
                            padding: const EdgeInsets.all(0),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          color: Colors.black,
                          icon: const Icon(
                            Icons.emoji_emotions_outlined,
                            color: Colors.black,
                            weight: 32,
                          )),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButtonTheme(
                      data: ElevatedButtonThemeData(
                        style: ButtonStyle(
                          foregroundColor: WidgetStateProperty.resolveWith(
                            (states) => Colors.white,
                          ),
                          backgroundColor: WidgetStateProperty.resolveWith<Color>(
                            (Set<WidgetState> states) {
                              final disabled = states.contains(WidgetState.disabled);
                              return const Color(0xff5B2DC1).withOpacity(disabled ? 0.4 : 1);
                            },
                          ),
                          padding: WidgetStateProperty.resolveWith(
                            (states) => const EdgeInsets.fromLTRB(12, 4, 12, 4),
                          ),
                        ),
                      ),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 36),
                        child: ElevatedButton(
                          onPressed: _sendButtonEnabled
                              ? () {
                                  if (_textController.text.trim().isEmpty) {
                                    // TODO: this
                                    return;
                                  }

                                  if (widget.onTapSend != null) {
                                    widget.onTapSend!(_textController.text.trim());
                                  }
                                }
                              : null,
                          child: const Text(
                            // TODO:~翻
                            'Send',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _setBottomPadding(BuildContext context) {
    setState(() {
      _bottomPadding = MediaQuery.of(context).viewInsets.bottom;
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }
}
