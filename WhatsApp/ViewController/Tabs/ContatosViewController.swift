//
//  ContatosViewController.swift
//  WhatsApp
//
//  Created by Jamilton  Damasceno
//  Copyright © Curso IOS. All rights reserved.
//

import UIKit
import FirebaseUI
import FirebaseAuth
import FirebaseFirestore

class ContatosViewController: UIViewController, UITableViewDelegate,UITableViewDataSource, UISearchBarDelegate {
    
    
    @IBOutlet weak var tableViewContatos: UITableView!
    @IBOutlet weak var searchBarContatos: UISearchBar!
    
    var auth: Auth!
    var db: Firestore!
    var idUsuarioLogado: String!
    var listaContatos: [Dictionary<String, Any>] = []
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        searchBarContatos.delegate = self
        tableViewContatos.separatorStyle = .none
        
        
        auth = Auth.auth()
        db = Firestore.firestore()
        
        //Recuperar id usuario logado
        if let id = auth.currentUser?.uid {
            self.idUsuarioLogado = id
        }
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        recuperarContatos()
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchText == "" {
            recuperarContatos()
        }
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        if let textoResultado = searchBar.text {
            if textoResultado != "" {
                pesquisarContatos(texto: textoResultado)
            }
        }
    }
    
    func pesquisarContatos(texto: String) {
        
        let listaFiltro: [Dictionary<String, Any>] = self.listaContatos
        self.listaContatos.removeAll()
        
        for item in listaFiltro {
            if let nome = item["nome"] as? String {
                if nome.lowercased().contains(texto.lowercased()) {
                    self.listaContatos.append(item)
                }
            }
        }
        
        self.tableViewContatos.reloadData()
        
    }
    
    func recuperarContatos(){
        
        self.listaContatos.removeAll()
        db.collection("usuarios")
        .document( idUsuarioLogado )
        .collection("contatos")
            .getDocuments { (snapshotResultado, erro) in
                
                if let snapshot = snapshotResultado {
                    for document in snapshot.documents {
                        
                        let dadosContato = document.data()
                        self.listaContatos.append(dadosContato)
                        
                    }
                    self.tableViewContatos.reloadData()
                }
                
        }
        
    }
    
    /*Métodos para listagem na tabela */
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let totalContato = self.listaContatos.count
        
        if totalContato == 0 {
            return 1
        }
        return totalContato
        
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let celula = tableView.dequeueReusableCell(withIdentifier: "celulaContatos", for: indexPath) as! ContatoTableViewCell
        
        celula.fotoContato.isHidden = false
        if self.listaContatos.count == 0 {
            celula.textoNome.text = "Nenhum contato cadastrado"
            celula.textoEmail.text = ""
            celula.fotoContato.isHidden = true
            return celula
        }
        
        let indice = indexPath.row
        let dadosContato = self.listaContatos[indice]
        
        celula.textoNome.text = dadosContato["nome"] as? String
        celula.textoEmail.text = dadosContato["email"] as? String
        
        if let foto = dadosContato["urlImagem"] as? String {
            celula.fotoContato.sd_setImage(with: URL(string: foto), completed: nil)
        }else{
            celula.fotoContato.image = UIImage(named: "imagem-perfil")
        }
        
        return celula
        
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        self.tableViewContatos.deselectRow(at: indexPath, animated: true)
        
        let indice = indexPath.row
        let contato = self.listaContatos[indice]
        
        self.performSegue(withIdentifier: "iniciarConversaContato", sender: contato)
        
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "iniciarConversaContato" {
            let viewDestino = segue.destination as! MensagensViewController
            viewDestino.contato = sender as? Dictionary
        }
    }

}
