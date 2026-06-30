import 'package:country_picker/country_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:uber_users_app/appInfo/auth_provider.dart';
import 'package:uber_users_app/authentication/user_information_screen.dart';
import 'package:uber_users_app/methods/common_methods.dart';
import 'package:uber_users_app/pages/blocked_screen.dart';
import 'package:uber_users_app/pages/home_page.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController phoneController = TextEditingController();
  CommonMethods commonMethods = CommonMethods();

  static const Color _primary = Color(0xFF111111);
  static const double _radius = 14;
  static const double _controlHeight = 56;

  Country selectedCountry = Country(
    phoneCode: '92',
    countryCode: 'PK',
    e164Sc: 0,
    geographic: true,
    level: 1,
    name: 'Pakistan',
    example: 'Pakistan',
    displayName: 'Pakistan',
    displayNameNoCountryCode: 'PK',
    e164Key: '',
  );

  @override
  void dispose() {
    phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthenticationProvider>(context);
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24),
              _buildHeader(),
              const SizedBox(height: 36),
              const Text(
                "Mobile Number",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _primary,
                ),
              ),
              const SizedBox(height: 8),
              _buildPhoneField(),
              const SizedBox(height: 20),
              _buildContinueButton(authProvider),
              const SizedBox(height: 24),
              _buildOrDivider(),
              const SizedBox(height: 24),
              _socialButton(
                onPressed:
                    authProvider.isLoading ? null : _handleGoogleSignIn,
                loading: authProvider.isGoogleSigInLoading,
                icon: _googleLogo(),
                label: "Continue with Google",
              ),
              const SizedBox(height: 14),
              _socialButton(
                onPressed: () {},
                loading: false,
                icon: const Icon(Icons.apple, color: _primary, size: 24),
                label: "Continue with Apple",
              ),
              const SizedBox(height: 28),
              Text(
                "By proceeding, you consent to receive calls, WhatsApp or "
                "SMS messages, including by automated means, from Uber and "
                "its affiliates to the number provided.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 12,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Center(
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: _primary,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.local_taxi_rounded,
              color: Colors.white,
              size: 38,
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            "Welcome",
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: _primary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "Sign in or create an account to get moving",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildPhoneField() {
    final bool isComplete = phoneController.text.length == 10;
    return TextFormField(
      controller: phoneController,
      maxLength: 10,
      textInputAction: TextInputAction.done,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      onChanged: (_) => setState(() {}),
      decoration: InputDecoration(
        counterText: '',
        hintText: '313 7426256',
        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 16),
        filled: true,
        fillColor: Colors.grey.shade50,
        contentPadding: const EdgeInsets.symmetric(vertical: 16),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_radius),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_radius),
          borderSide: const BorderSide(color: _primary, width: 1.5),
        ),
        prefixIcon: InkWell(
          onTap: _openCountryPicker,
          borderRadius: BorderRadius.circular(_radius),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(selectedCountry.flagEmoji,
                    style: const TextStyle(fontSize: 20)),
                const SizedBox(width: 6),
                Text(
                  '+${selectedCountry.phoneCode}',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const Icon(Icons.arrow_drop_down, color: Colors.grey),
                const SizedBox(width: 8),
                Container(width: 1, height: 24, color: Colors.grey.shade300),
              ],
            ),
          ),
        ),
        suffixIcon: isComplete
            ? Container(
                height: 22,
                width: 22,
                margin: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                    shape: BoxShape.circle, color: Color(0xFF1DB954)),
                child: const Icon(Icons.check, size: 16, color: Colors.white),
              )
            : null,
      ),
    );
  }

  Widget _buildContinueButton(AuthenticationProvider authProvider) {
    return SizedBox(
      height: _controlHeight,
      child: ElevatedButton(
        onPressed: authProvider.isLoading ? null : sendPhoneNumber,
        style: ElevatedButton.styleFrom(
          backgroundColor: _primary,
          disabledBackgroundColor: Colors.grey.shade300,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_radius),
          ),
        ),
        child: authProvider.isLoading
            ? const SizedBox(
                height: 22,
                width: 22,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white),
              )
            : const Text(
                "Continue",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }

  Widget _buildOrDivider() {
    return Row(
      children: [
        Expanded(child: Divider(color: Colors.grey.shade300, thickness: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            "or",
            style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
          ),
        ),
        Expanded(child: Divider(color: Colors.grey.shade300, thickness: 1)),
      ],
    );
  }

  Widget _socialButton({
    required VoidCallback? onPressed,
    required bool loading,
    required Widget icon,
    required String label,
  }) {
    return SizedBox(
      height: _controlHeight,
      child: OutlinedButton(
        onPressed: loading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white,
          side: BorderSide(color: Colors.grey.shade300),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_radius),
          ),
        ),
        child: loading
            ? const SizedBox(
                height: 22,
                width: 22,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: _primary),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  icon,
                  const SizedBox(width: 10),
                  Text(
                    label,
                    style: const TextStyle(
                      color: _primary,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _googleLogo() {
    return Container(
      width: 22,
      height: 22,
      alignment: Alignment.center,
      child: const Text(
        'G',
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Color(0xFF4285F4),
        ),
      ),
    );
  }

  void _openCountryPicker() {
    showCountryPicker(
      context: context,
      showPhoneCode: true,
      countryListTheme: const CountryListThemeData(
        bottomSheetHeight: 500,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      onSelect: (value) => setState(() => selectedCountry = value),
    );
  }

  Future<void> _handleGoogleSignIn() async {
    final authProvider =
        Provider.of<AuthenticationProvider>(context, listen: false);
    if (authProvider.isLoading) return;

    await authProvider.signInWithGoogle(
      context,
      () async {
        bool userExits = await authProvider.checkUserExistById();
        bool userExistInDatabse = await authProvider.checkUserExistByEmail(
            authProvider.firebaseAuth.currentUser!.email!.toString());

        if (userExits) {
          if (userExistInDatabse) {
            bool isBlocked = await authProvider.checkIfUserIsBlocked();
            if (isBlocked) {
              if (!mounted) return;
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const BlockedScreen()),
              );
            } else {
              await authProvider.getUserDataFromFirebaseDatabase();
              navigate(isSingedIn: true);
            }
          }
        } else {
          navigate(isSingedIn: false);
        }
      },
    );
  }

  void sendPhoneNumber() {
    final authRepo =
        Provider.of<AuthenticationProvider>(context, listen: false);
    String phoneNumber = phoneController.text.trim();

    // Validate the phone number
    if (phoneNumber.isEmpty ||
        phoneNumber.length != 10 ||
        !RegExp(r'^[3][0-9]{9}$').hasMatch(phoneNumber)) {
      // Show error if the phone number is invalid
      commonMethods.displaySnackBar(
        "Please enter a valid mobile number.",
        context,
      );
      return;
    }

    // Append country code
    String fullPhoneNumber = '+${selectedCountry.phoneCode}$phoneNumber';

    // Proceed with phone number authentication
    authRepo.signInWithPhone(
      context: context,
      phoneNumber: fullPhoneNumber,
    );
  }

  void navigate({required bool isSingedIn}) {
    if (isSingedIn) {
      Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const HomePage()),
          (route) => false);
    } else {
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => const UserInformationScreen()));
    }
  }
}
