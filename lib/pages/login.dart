import 'package:flutter/material.dart';
import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:plannerop/core/model/user.dart';
import 'package:plannerop/dto/auth/signin.dart';
import 'package:plannerop/pages/supervisor/home.dart';
import 'package:plannerop/services/auth/signin.dart';
import 'package:plannerop/store/auth.dart';
import 'package:plannerop/store/user.dart';
import 'package:plannerop/utils/toast.dart';
import 'package:provider/provider.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FocusNode _usernameFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();
  final SigninService _signinService = SigninService();

  void _onFocusChange() {
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    _usernameFocusNode.addListener(_onFocusChange);
    _passwordFocusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _usernameFocusNode.removeListener(_onFocusChange);
    _passwordFocusNode.removeListener(_onFocusChange);
    _usernameController.dispose();
    _passwordController.dispose();
    _usernameFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      try {
        // Mostrar indicador de carga (opcional)
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) => const Center(
            child: CircularProgressIndicator(),
          ),
        );

        final ResSigninDto response = await _signinService.signin(
          _usernameController.text,
          _passwordController.text,
        );

        // Cerrar el diálogo de carga
        if (mounted) {
          Navigator.of(context).pop();
        }

        if (response.isSuccess) {
          if (!mounted) return; // Verificar si todavía está montado

          // Guarda el token de acceso en el provider de autenticación
          final authProvider =
              Provider.of<AuthProvider>(context, listen: false);
          authProvider.setAccessToken(response.accessToken);

          // Decodificar el token
          final decodedToken = JwtDecoder.decode(response.accessToken);

          if (!mounted)
            return; // Verificar de nuevo después de operaciones potencialmente lentas

          final userProvider =
              Provider.of<UserProvider>(context, listen: false);
          userProvider.setUser(User(
            name: decodedToken['username'],
            id: decodedToken['id'],
            dni: decodedToken['dni'],
            phone: decodedToken['phone'],
          ));

          debugPrint('Token decodificado: $decodedToken');

          if (!mounted) return; // Verificar nuevamente antes de la navegación

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const SupervisorHome()),
          );
        } else {
          if (!mounted) return; // Verificar si todavía está montado

          // Si el inicio de sesión falla, muestra un mensaje de error
          showErrorToast(context, 'Usuario o contraseña incorrectos');
        }
      } catch (e) {
        debugPrint('Error en login: $e');

        // Cerrar el diálogo de carga si hay error
        if (mounted) {
          Navigator.of(context).pop();
          showErrorToast(context, 'Error de conexión: $e');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: 300,
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(20.0),
                  bottomRight: Radius.circular(20.0),
                ),
                child: SvgPicture.asset(
                  'assets/auth.svg',
                  width: double.infinity,
                  fit: BoxFit.contain,
                  height: 300,
                ),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      const SizedBox(height: 20),
                      Neumorphic(
                        style: NeumorphicStyle(
                          depth: -4,
                          intensity: 0.8,
                          boxShape: NeumorphicBoxShape.roundRect(
                              BorderRadius.circular(12)),
                        ),
                        child: TextFormField(
                          controller: _usernameController,
                          focusNode: _usernameFocusNode,
                          decoration: const InputDecoration(
                            labelText: 'Usuario',
                            prefixIcon: Icon(Icons.person),
                            border: InputBorder.none,
                            filled: true,
                            fillColor: Colors.white,
                            errorStyle: TextStyle(
                              backgroundColor: Colors.transparent,
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Por favor ingrese su usuario';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(height: 20),
                      Neumorphic(
                        style: NeumorphicStyle(
                          depth: -4,
                          intensity: 0.8,
                          boxShape: NeumorphicBoxShape.roundRect(
                              BorderRadius.circular(12)),
                        ),
                        child: TextFormField(
                          controller: _passwordController,
                          focusNode: _passwordFocusNode,
                          decoration: const InputDecoration(
                            labelText: 'Contraseña',
                            prefixIcon: Icon(Icons.lock),
                            border: InputBorder.none,
                            filled: true,
                            fillColor: Colors.white,
                          ),
                          obscureText: true,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Por favor ingrese su contraseña';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(height: 20),
                      NeumorphicButton(
                        onPressed: () async {
                          if (_formKey.currentState!.validate()) {
                            await _login();
                          }
                        },
                        style: NeumorphicStyle(
                          shape: NeumorphicShape.flat,
                          depth: 8,
                          intensity: 1.0,
                          boxShape: NeumorphicBoxShape.roundRect(
                              BorderRadius.circular(12)),
                          color: Colors.blue, // Cambia el color del botón
                        ),
                        padding: const EdgeInsets.symmetric(
                            vertical: 16.0,
                            horizontal: 32.0), // Aumenta el tamaño del botón
                        child: const Center(
                          child: Text(
                            'Ingresar',
                            style: TextStyle(
                              fontSize: 20, // Aumenta el tamaño del texto
                              fontWeight: FontWeight.bold,
                              color: Colors.white, // Cambia el color del texto
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
