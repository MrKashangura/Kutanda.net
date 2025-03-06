// lib/shared/widgets/custom_textfield.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A customized text field widget that maintains consistent styling
/// throughout the Kutanda Plant Auction app.
class CustomTextField extends StatelessWidget {
  /// The controller for the text field
  final TextEditingController? controller;
  
  /// The label text displayed above the text field
  final String? label;
  
  /// The hint text displayed when the text field is empty
  final String? hint;
  
  /// The helper text displayed below the text field
  final String? helperText;
  
  /// The error text displayed when validation fails
  final String? errorText;
  
  /// The icon displayed at the start of the text field
  final IconData? prefixIcon;
  
  /// The icon displayed at the end of the text field
  final IconData? suffixIcon;
  
  /// The action to perform when the suffix icon is pressed
  final VoidCallback? onSuffixIconPressed;
  
  /// The type of keyboard to display
  final TextInputType keyboardType;
  
  /// Whether to obscure the text (for passwords)
  final bool obscureText;
  
  /// Whether the text field is enabled
  final bool enabled;
  
  /// The maximum number of lines for the text field
  final int? maxLines;
  
  /// The minimum number of lines for the text field
  final int? minLines;
  
  /// The maximum length of the text field
  final int? maxLength;
  
  /// The list of input formatters to apply to the text field
  final List<TextInputFormatter>? inputFormatters;
  
  /// The function to call when the text field value changes
  final Function(String)? onChanged;
  
  /// The function to call when the user submits the text field
  final Function(String)? onSubmitted;
  
  /// The function to call to validate the text field value
  final String? Function(String?)? validator;
  
  /// The text alignment within the text field
  final TextAlign textAlign;
  
  /// The text style for the text field
  final TextStyle? textStyle;
  
  /// Whether to automatically focus this text field
  final bool autofocus;
  
  /// The focus node for this text field
  final FocusNode? focusNode;
  
  /// The action to take when the user submits the text field
  final TextInputAction? textInputAction;
  
  /// Whether to enable suggestions
  final bool enableSuggestions;
  
  /// Whether to enable autocorrect
  final bool autocorrect;
  
  /// Custom decoration for the text field
  final InputDecoration? decoration;
  
  /// Creates a customized text field with consistent styling.
  const CustomTextField({
    super.key,
    this.controller,
    this.label,
    this.hint,
    this.helperText,
    this.errorText,
    this.prefixIcon,
    this.suffixIcon,
    this.onSuffixIconPressed,
    this.keyboardType = TextInputType.text,
    this.obscureText = false,
    this.enabled = true,
    this.maxLines = 1,
    this.minLines,
    this.maxLength,
    this.inputFormatters,
    this.onChanged,
    this.onSubmitted,
    this.validator,
    this.textAlign = TextAlign.start,
    this.textStyle,
    this.autofocus = false,
    this.focusNode,
    this.textInputAction,
    this.enableSuggestions = true,
    this.autocorrect = true,
    this.decoration,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    // Default text field decoration
    final defaultDecoration = InputDecoration(
      labelText: label,
      hintText: hint,
      helperText: helperText,
      errorText: errorText,
      prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null,
      suffixIcon: suffixIcon != null
          ? IconButton(
              icon: Icon(suffixIcon),
              onPressed: onSuffixIconPressed,
            )
          : null,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: theme.colorScheme.outline),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: theme.colorScheme.outline.withOpacity(0.7)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: theme.colorScheme.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: theme.colorScheme.error),
      ),
      filled: true,
      fillColor: enabled 
          ? theme.colorScheme.surface 
          : theme.colorScheme.surfaceVariant.withOpacity(0.5),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
    
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      enabled: enabled,
      maxLines: obscureText ? 1 : maxLines,
      minLines: minLines,
      maxLength: maxLength,
      inputFormatters: inputFormatters,
      onChanged: onChanged,
      onFieldSubmitted: onSubmitted,
      validator: validator,
      textAlign: textAlign,
      style: textStyle ?? theme.textTheme.bodyMedium?.copyWith(
        color: enabled ? theme.colorScheme.onSurface : theme.colorScheme.onSurface.withOpacity(0.6),
      ),
      autofocus: autofocus,
      focusNode: focusNode,
      textInputAction: textInputAction,
      enableSuggestions: enableSuggestions,
      autocorrect: autocorrect,
      decoration: decoration ?? defaultDecoration,
    );
  }
}

/// A text field specifically designed for email input
class EmailTextField extends StatelessWidget {
  final TextEditingController controller;
  final String? label;
  final String? hint;
  final String? errorText;
  final bool enabled;
  final bool autofocus;
  final FocusNode? focusNode;
  final TextInputAction? textInputAction;
  final Function(String)? onSubmitted;
  
  const EmailTextField({
    super.key,
    required this.controller,
    this.label = 'Email',
    this.hint = 'Enter your email address',
    this.errorText,
    this.enabled = true,
    this.autofocus = false,
    this.focusNode,
    this.textInputAction = TextInputAction.next,
    this.onSubmitted,
  });
  
  @override
  Widget build(BuildContext context) {
    return CustomTextField(
      controller: controller,
      label: label,
      hint: hint,
      errorText: errorText,
      prefixIcon: Icons.email,
      keyboardType: TextInputType.emailAddress,
      enabled: enabled,
      autofocus: autofocus,
      focusNode: focusNode,
      textInputAction: textInputAction,
      onSubmitted: onSubmitted,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter an email address';
        }
        
        // Simple email validation
        if (!RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(value)) {
          return 'Please enter a valid email address';
        }
        
        return null;
      },
    );
  }
}

/// A text field specifically designed for password input
class PasswordTextField extends StatefulWidget {
  final TextEditingController controller;
  final String? label;
  final String? hint;
  final String? errorText;
  final bool enabled;
  final bool autofocus;
  final FocusNode? focusNode;
  final TextInputAction? textInputAction;
  final Function(String)? onSubmitted;
  final bool isConfirmPassword;
  final TextEditingController? passwordController;
  
  const PasswordTextField({
    super.key,
    required this.controller,
    this.label = 'Password',
    this.hint = 'Enter your password',
    this.errorText,
    this.enabled = true,
    this.autofocus = false,
    this.focusNode,
    this.textInputAction = TextInputAction.done,
    this.onSubmitted,
    this.isConfirmPassword = false,
    this.passwordController,
  });
  
  @override
  PasswordTextFieldState createState() => PasswordTextFieldState();
}

class PasswordTextFieldState extends State<PasswordTextField> {
  bool _obscureText = true;
  
  @override
  Widget build(BuildContext context) {
    return CustomTextField(
      controller: widget.controller,
      label: widget.label,
      hint: widget.hint,
      errorText: widget.errorText,
      prefixIcon: Icons.lock,
      suffixIcon: _obscureText ? Icons.visibility : Icons.visibility_off,
      onSuffixIconPressed: () {
        setState(() {
          _obscureText = !_obscureText;
        });
      },
      obscureText: _obscureText,
      enabled: widget.enabled,
      autofocus: widget.autofocus,
      focusNode: widget.focusNode,
      textInputAction: widget.textInputAction,
      onSubmitted: widget.onSubmitted,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter a password';
        }
        
        if (!widget.isConfirmPassword && value.length < 6) {
          return 'Password must be at least 6 characters';
        }
        
        if (widget.isConfirmPassword && widget.passwordController != null) {
          if (value != widget.passwordController!.text) {
            return 'Passwords do not match';
          }
        }
        
        return null;
      },
    );
  }
}

/// A text field specifically designed for phone number input
class PhoneTextField extends StatelessWidget {
  final TextEditingController controller;
  final String? label;
  final String? hint;
  final String? errorText;
  final bool enabled;
  final bool autofocus;
  final FocusNode? focusNode;
  final TextInputAction? textInputAction;
  final Function(String)? onSubmitted;
  
  const PhoneTextField({
    super.key,
    required this.controller,
    this.label = 'Phone Number',
    this.hint = 'Enter your phone number',
    this.errorText,
    this.enabled = true,
    this.autofocus = false,
    this.focusNode,
    this.textInputAction = TextInputAction.next,
    this.onSubmitted,
  });
  
  @override
  Widget build(BuildContext context) {
    return CustomTextField(
      controller: controller,
      label: label,
      hint: hint,
      errorText: errorText,
      prefixIcon: Icons.phone,
      keyboardType: TextInputType.phone,
      enabled: enabled,
      autofocus: autofocus,
      focusNode: focusNode,
      textInputAction: textInputAction,
      onSubmitted: onSubmitted,
      // Format the phone number as the user types
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(12),
      ],
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter a phone number';
        }
        
        // Simple phone validation
        if (value.length < 10) {
          return 'Please enter a valid phone number';
        }
        
        return null;
      },
    );
  }
}

/// A text field specifically designed for price/currency input
class PriceTextField extends StatelessWidget {
  final TextEditingController controller;
  final String? label;
  final String? hint;
  final String? errorText;
  final bool enabled;
  final bool autofocus;
  final FocusNode? focusNode;
  final TextInputAction? textInputAction;
  final Function(String)? onSubmitted;
  final String currencySymbol;
  final double? minValue;
  final double? maxValue;
  
  const PriceTextField({
    super.key,
    required this.controller,
    this.label = 'Price',
    this.hint = 'Enter price',
    this.errorText,
    this.enabled = true,
    this.autofocus = false,
    this.focusNode,
    this.textInputAction = TextInputAction.next,
    this.onSubmitted,
    this.currencySymbol = '\$',
    this.minValue,
    this.maxValue,
  });
  
  @override
  Widget build(BuildContext context) {
    return CustomTextField(
      controller: controller,
      label: label,
      hint: hint,
      errorText: errorText,
      prefixIcon: Icons.attach_money,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      enabled: enabled,
      autofocus: autofocus,
      focusNode: focusNode,
      textInputAction: textInputAction,
      onSubmitted: onSubmitted,
      // Allow only numbers with decimal point
      inputFormatters: [
    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
      ],
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter a price';
        }
        
        final double? price = double.tryParse(value);
        if (price == null) {
          return 'Please enter a valid price';
        }
        
        if (minValue != null && price < minValue!) {
          return 'Price cannot be less than ${currencySymbol}${minValue!.toStringAsFixed(2)}';
        }
        
        if (maxValue != null && price > maxValue!) {
          return 'Price cannot be more than ${currencySymbol}${maxValue!.toStringAsFixed(2)}';
        }
        
        return null;
      },
      // Custom decoration with currency symbol
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        errorText: errorText,
        prefixIcon: const Icon(Icons.attach_money),
        prefixText: currencySymbol,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}

/// A text field specifically designed for search input
class SearchTextField extends StatelessWidget {
  final TextEditingController controller;
  final String? hint;
  final Function(String)? onChanged;
  final VoidCallback? onClear;
  final bool enabled;
  final bool autofocus;
  final FocusNode? focusNode;
  
  const SearchTextField({
    super.key,
    required this.controller,
    this.hint = 'Search...',
    this.onChanged,
    this.onClear,
    this.enabled = true,
    this.autofocus = false,
    this.focusNode,
  });
  
  @override
  Widget build(BuildContext context) {
    return CustomTextField(
      controller: controller,
      hint: hint,
      prefixIcon: Icons.search,
      suffixIcon: controller.text.isNotEmpty ? Icons.clear : null,
      onSuffixIconPressed: () {
        controller.clear();
        if (onClear != null) {
          onClear!();
        }
        if (onChanged != null) {
          onChanged!('');
        }
      },
      onChanged: (value) {
        if (onChanged != null) {
          onChanged!(value);
        }
      },
      enabled: enabled,
      autofocus: autofocus,
      focusNode: focusNode,
      textInputAction: TextInputAction.search,
      // Custom decoration for search field
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: const Icon(Icons.search),
        suffixIcon: controller.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  controller.clear();
                  if (onClear != null) {
                    onClear!();
                  }
                  if (onChanged != null) {
                    onChanged!('');
                  }
                },
              )
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(50),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(50),
          borderSide: BorderSide(color: Colors.grey.withOpacity(0.5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(50),
          borderSide: BorderSide(color: Theme.of(context).primaryColor),
        ),
        filled: true,
        fillColor: Theme.of(context).colorScheme.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
      ),
    );
  }
}