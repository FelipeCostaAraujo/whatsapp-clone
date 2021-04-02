//
//  CadastroContatoViewController.swift
//  WhatsApp
//
//  Created by Jamilton  Damasceno.
//  Copyright © Curso IOS. All rights reserved.
//

import UIKit
import FirebaseAuth
import FirebaseFirestore

class CadastroContatoViewController: UIViewController {
    
    @IBOutlet weak var campoEmail: UITextField!
    @IBOutlet weak var mensagemErro: UILabel!
    
    var idUsuarioLogado: String!
    var emailUsuarioLogado: String!
    
    var auth: Auth!
    var db: Firestore!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        auth = Auth.auth()
        db = Firestore.firestore()
        
        if let currentUser = auth.currentUser {
            self.idUsuarioLogado = currentUser.uid
            self.emailUsuarioLogado = currentUser.email
        }
        
    }
    
    @IBAction func cadastrarContato(_ sender: Any) {
        
        self.mensagemErro.isHidden = true
        
        //Verifica e está adicionado próprio e-mail
        if let emailDigitado = campoEmail.text {
            if emailDigitado == self.emailUsuarioLogado {
                mensagemErro.isHidden = false
                mensagemErro.text = "Você está adicionado seu próprio email!"
                return
            }
            
            //Verifica se existe o usuário no Firebase
            db.collection("usuarios")
            .whereField("email", isEqualTo: emailDigitado)
                .getDocuments { (snapshotResultado, erro) in
                    
                    //Conta total de retorno
                    if let totalItens = snapshotResultado?.count {
                        if totalItens == 0 {
                            self.mensagemErro.text = "Usuário não cadastrado!"
                            self.mensagemErro.isHidden = false
                            return
                        }
                    }
                    
                    //Salva contato
                    if let snapshot = snapshotResultado {
                        
                        for document in snapshot.documents {
                            let dados = document.data()
                            self.salvarContato(dadosContato: dados)
                        }
                        
                    }
                    
            }
            
        }
        
    }
    
    func salvarContato(dadosContato: Dictionary<String, Any>) {
        
        if let idUsuarioContato = dadosContato["id"] {
            db.collection("usuarios")
            .document( idUsuarioLogado )
            .collection("contatos")
            .document( String(describing: idUsuarioContato) )
                .setData(dadosContato) { (erro) in
                    if erro == nil {
                        self.navigationController?.popViewController(animated: true)
                        
                    }
            }
        }

        
    }
    

}
