//
//  LoginViewController.swift
//  WhatsApp
//
//  Created by Jamilton  Damasceno.
//  Copyright ©  Curso IOS. All rights reserved.
//

import UIKit
import FirebaseAuth

class LoginViewController: UIViewController {
    
    @IBOutlet weak var campoEmail: UITextField!
    @IBOutlet weak var campoSenha: UITextField!
    var auth: Auth!
    var handler: AuthStateDidChangeListenerHandle!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        auth = Auth.auth()
        
        //Adiciona listener para autenticacao de usuario
        handler = auth.addStateDidChangeListener { (autenticacao, usuario) in
            
            if usuario != nil {
                self.performSegue(withIdentifier: "segueLoginAutomatico", sender: nil)
            }
            
        }
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        //auth.removeStateDidChangeListener(handler)
    }
    
    @IBAction func logar(_ sender: Any) {
        
        if let email = campoEmail.text {
            if let senha = campoSenha.text {
                
                auth.signIn(withEmail: email, password: senha) { (usuario, erro) in
                    
                    if erro == nil {
                        if let usuarioLogado = usuario {
                            print("Sucesso ao logar usuario! \(String(describing: usuarioLogado.user.email)) ")
                        }
                    }else{
                        print("Erro ao autenticar usuario!")
                    }
                    
                }
                
            }else{
                print("Digite seu senha")
            }
        }else{
            print("Digite seu email")
        }
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        navigationController?.setNavigationBarHidden(true, animated: true)
    }
    
    @IBAction func unwindToLogin(_ unwindSegue: UIStoryboardSegue) {
        
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
