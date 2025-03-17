// lib/screens/client_details_container.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/navigation_state.dart';
import '../models/user_model.dart';
import '../services/database_service.dart';
import 'client_screens.dart'; // importamos el archivo original que contiene ClientDetailsScreen

class ClientDetailsContainer extends StatelessWidget {
  final String? clientId;

  const ClientDetailsContainer({Key? key, this.clientId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Detalles del Cliente'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            // Volvemos a la lista de clientes utilizando el gestor de estado
            Provider.of<NavigationState>(context, listen: false)
                .setSelectedIndex(1);
          },
        ),
      ),
      body: ClientDetailsScreen(clientId: clientId),
    );
  }
}
