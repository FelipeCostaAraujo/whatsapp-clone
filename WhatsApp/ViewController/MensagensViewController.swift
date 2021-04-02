//
//  MensagensViewController.swift
//  WhatsApp
//
//  Created by Jamilton  Damasceno.
//  Copyright © Curso IOS. All rights reserved.
//

import UIKit
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage

class MensagensViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    @IBOutlet weak var tableViewMensagens: UITableView!
    @IBOutlet weak var fotoBotao: UIButton!
    
    @IBOutlet weak var mensagemCaixaTexto: UITextField!
    
    var listaMensagens: [Dictionary<String, Any>]! = []
    var idUsuarioLogado: String!
    var contato: Dictionary<String, Any>!
    var mensagensListener: ListenerRegistration!
    var imagePicker = UIImagePickerController()
    
    var nomeContato: String!
    var urlFotoContato: String!
    var nomeUsuarioLogado: String!
    var urlFotoUsuarioLogado: String!
    
    var auth: Auth!
    var db: Firestore!
    var storage: Storage!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        auth = Auth.auth()
        db = Firestore.firestore()
        storage = Storage.storage()
        
        imagePicker.delegate = self
        
        //Recuperar id usuario logado
        if let id = auth.currentUser?.uid {
            self.idUsuarioLogado = id
            recuperaDadosUsuarioLogado()
        }
        
        //Configura título da tela
        if let nome = contato["nome"] as? String {
            nomeContato = nome
            self.navigationItem.title = nomeContato
        }
        
        if let url = contato["urlImagem"] as? String {
            urlFotoContato = url
        }

        //configurações da tableView
        tableViewMensagens.separatorStyle = .none
        tableViewMensagens.backgroundView = UIImageView(image: UIImage(named: "bg"))
        
        //Configura lista de mensagens
        //listaMensagens = ["Olá, tudo bem?", "Tudo ótimo meu amigo", "Estou muito doente e precisava falar com você, será que poderia ir na farmácia pegar alguns remédios?", "Posso sim, quais?", "Pode pegar um Resfenol, pode ser aquele dia e noite, sabe qual é?", "Sei sim!!", "Excelente!!Muuuuuuuito obrigadooo!!", "Por nada!! espero que melhore logo"]
        
    }
    
    func recuperaDadosUsuarioLogado() {
        
        let usuarios = db.collection("usuarios")
        .document( idUsuarioLogado )
        
        usuarios.getDocument { (documentSnapshot, erro) in
            
            if erro == nil {
                if let dados = documentSnapshot?.data() {
                    if let url = dados["urlImagem"] as? String {
                            if let nome = dados["nome"] as? String {
                                self.urlFotoUsuarioLogado = url
                                self.nomeUsuarioLogado = nome
                            }
                    }
                }
            }
            
        }
        
    }
    
    @IBAction func enviarImagem(_ sender: Any) {
        
        imagePicker.sourceType = .savedPhotosAlbum
        present(imagePicker, animated: true, completion: nil)
        
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        let imagemRecuperada = info[ UIImagePickerController.InfoKey.originalImage ] as! UIImage
        
        let imagens = storage
                    .reference()
                    .child("imagens")
        
        if let imagemUpload = imagemRecuperada.jpegData(compressionQuality: 0.3) {
            
            let identificadorUnico = UUID().uuidString
            let nomeImagem = "\(identificadorUnico).jpg"
            let imagemMensagemRef = imagens.child("mensagens").child( nomeImagem )
            
            imagemMensagemRef.putData(imagemUpload, metadata: nil) { (metaData, erro) in
                
                if erro == nil {
                    print("Sucesso ao fazer upload da imagem")
                    
                    imagemMensagemRef.downloadURL { (url, erro) in
                        
                        if let urlImagem = url?.absoluteString {
                            
                            if let idUsuarioDestinatario = self.contato["id"] as? String {
                                
                                let mensagem: Dictionary<String, Any> = [
                                    "idUsuario" : self.idUsuarioLogado!,
                                    "urlImagem" : urlImagem,
                                    "data" : FieldValue.serverTimestamp()
                                ]
                            
                                //salvar mensagem para remetente
                                self.salvarMensagem(idRemetente: self.idUsuarioLogado, idDestinatario: idUsuarioDestinatario, mensagem: mensagem)
                                
                                //salvar mensagem para o destinatário
                                self.salvarMensagem(idRemetente: idUsuarioDestinatario, idDestinatario: self.idUsuarioLogado, mensagem: mensagem)
                                
                                var conversa: Dictionary<String, Any> = [
                                    "ultimaMensagem" : "imagem..."
                                ]
                                
                                //salvar conversa para remetente (dados quem recebe)
                                conversa["idRemetente"] = self.idUsuarioLogado!
                                conversa["idDestinatario"] = idUsuarioDestinatario
                                conversa["nomeUsuario"] = self.nomeContato!
                                conversa["urlFotoUsuario"] = self.urlFotoContato!
                                self.salvarConversa(idRemetente: self.idUsuarioLogado, idDestinatario: idUsuarioDestinatario, conversa: conversa)
                                
                                //salvar conversa para destinatário (dados quem envia)
                                conversa["idRemetente"] = idUsuarioDestinatario
                                conversa["idDestinatario"] = self.idUsuarioLogado
                                conversa["nomeUsuario"] = self.nomeUsuarioLogado
                                conversa["urlFotoUsuario"] = self.urlFotoUsuarioLogado
                                self.salvarConversa(idRemetente: idUsuarioDestinatario, idDestinatario: self.idUsuarioLogado, conversa: conversa)
                                
                            }
                            
                        }
                        
                    }
                    
                }else{
                    print("Erro ao fazer upload da imagem")
                }
                
            }
            
        }
        
        
        imagePicker.dismiss(animated: true, completion: nil)
        
    }
    
    
    @IBAction func enviarMensagem(_ sender: Any) {
        
        if let textoDigitado = mensagemCaixaTexto.text {
            if !textoDigitado.isEmpty {
                if let idUsuarioDestinatario = contato["id"] as? String {
                    
                    let mensagem: Dictionary<String, Any> = [
                        "idUsuario" : idUsuarioLogado!,
                        "texto" : textoDigitado,
                        "data" : FieldValue.serverTimestamp()
                    ]
                
                    //salvar mensagem para remetente
                    salvarMensagem(idRemetente: idUsuarioLogado, idDestinatario: idUsuarioDestinatario, mensagem: mensagem)
                    
                    //salvar mensagem para o destinatário
                    salvarMensagem(idRemetente: idUsuarioDestinatario, idDestinatario: idUsuarioLogado, mensagem: mensagem)
                    
                    var conversa: Dictionary<String, Any> = [
                        "ultimaMensagem" : textoDigitado
                    ]
                    
                    //salvar conversa para remetente (dados quem recebe)
                    conversa["idRemetente"] = idUsuarioLogado!
                    conversa["idDestinatario"] = idUsuarioDestinatario
                    conversa["nomeUsuario"] = self.nomeContato!
                    conversa["urlFotoUsuario"] = self.urlFotoContato!
                    salvarConversa(idRemetente: idUsuarioLogado, idDestinatario: idUsuarioDestinatario, conversa: conversa)
                    
                    //salvar conversa para destinatário (dados quem envia)
                    conversa["idRemetente"] = idUsuarioDestinatario
                    conversa["idDestinatario"] = idUsuarioLogado
                    conversa["nomeUsuario"] = self.nomeUsuarioLogado
                    conversa["urlFotoUsuario"] = self.urlFotoUsuarioLogado
                    salvarConversa(idRemetente: idUsuarioDestinatario, idDestinatario: idUsuarioLogado, conversa: conversa)
                    
                }
            }
        }
        
    }
    
    func salvarConversa(idRemetente: String, idDestinatario: String, conversa: Dictionary<String, Any>) {
        
        db.collection("conversas")
        .document( idRemetente )
        .collection( "ultimas_conversas" )
        .document( idDestinatario )
        .setData( conversa )
        
    }
    
    func salvarMensagem(idRemetente: String, idDestinatario: String, mensagem: Dictionary<String, Any>) {
        
        db.collection("mensagens")
            .document( idRemetente )
            .collection( idDestinatario )
            .addDocument(data: mensagem)
        
        //limpar caixa de texto
        mensagemCaixaTexto.text = ""
        
    }
    
    func addListenerRecuperarMensagens() {
        
        if let idDestinatario = contato["id"] as? String {
            mensagensListener = db.collection("mensagens")
            .document( idUsuarioLogado )
            .collection( idDestinatario )
            .order(by: "data", descending: false)
                .addSnapshotListener { (querySnapshot, erro) in
                    
                    //limpa lista
                    self.listaMensagens.removeAll()
                    
                    //Recupera dados
                    if let snapshot = querySnapshot {
                        for document in snapshot.documents {
                            let dados = document.data()
                            self.listaMensagens.append(dados)
                        }
                        self.tableViewMensagens.reloadData()
                    }
                    
            }
        }
        
    }
    
    /*Métodos para listagem na tabela */
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.listaMensagens.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let celulaDireita = tableView.dequeueReusableCell(withIdentifier: "celulaMensagensDireita", for: indexPath) as! MensagensTableViewCell
        
        let celulaEsquerda = tableView.dequeueReusableCell(withIdentifier: "celulaMensagensEsquerda", for: indexPath) as! MensagensTableViewCell
        
        let celulaImagemDireita = tableView.dequeueReusableCell(withIdentifier: "celulaImagemDireita", for: indexPath) as! MensagensTableViewCell
        
        let celulaImagemEsquerda = tableView.dequeueReusableCell(withIdentifier: "celulaImagemEsquerda", for: indexPath) as! MensagensTableViewCell
        
        let indice = indexPath.row
        let dados = self.listaMensagens[indice]
        let texto = dados["texto"] as? String
        let idUsuario = dados["idUsuario"] as? String
        let urlImagem = dados["urlImagem"] as? String
        
        if idUsuarioLogado == idUsuario {
            if urlImagem != nil {
                celulaImagemDireita.imagemDireita.sd_setImage(with: URL(string: urlImagem!), completed: nil)
                return celulaImagemDireita
            }
            celulaDireita.mensagemDireitaLabel.text = texto
            return celulaDireita
            
        }else{
            if urlImagem != nil {
                celulaImagemEsquerda.imagemEsquerda.sd_setImage(with: URL(string: urlImagem!), completed: nil)
                return celulaImagemEsquerda
            }
            celulaEsquerda.mensagemEsquerdaLabel.text = texto
            return celulaEsquerda
        }
        
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        self.tabBarController?.tabBar.isHidden = true
        
        addListenerRecuperarMensagens()
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        self.tabBarController?.tabBar.isHidden = false
        
        mensagensListener.remove()
        
    }

}
