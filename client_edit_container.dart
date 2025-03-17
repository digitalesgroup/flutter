// lib/screens/client_edit_container.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/navigation_state.dart';
import 'client_screens.dart'; // importamos el archivo original que contiene ClientEditScreen

class ClientEditContainer extends StatelessWidget {
  final String? clientId;

  const ClientEditContainer({Key? key, this.clientId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Editar Cliente'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            // Volvemos a la vista de detalles usando el gestor de estado
            Provider.of<NavigationState>(context, listen: false)
                .navigateToDetail('client', clientId ?? '');
          },
        ),
      ),
      body: ClientEditScreen(clientId: clientId),
    );
  }
}
