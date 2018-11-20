<?php
class BusMonitorTraitement /*extends Thread*/{
	public function __construct($Mode,$Data,$AdrSource,$AdrGroup){
		$this->Mode=$Mode;
		$this->Data=$Data;
		$this->AdrSource=$this->formatiaddr($AdrSource);
		$this->AdrGroup=$this->formatgaddr($AdrGroup);
	}
	public function run(){
		$monitor=array();
		$monitor['Mode']= $this->Mode;
		$monitor['AdresseGroupe']= $this->AdrGroup;
		$monitor['AdressePhysique']= $this->AdrSource;
		if(is_array($this->Data)){
			$monitor['data']='0x ';
			foreach ($this->Data as $Byte)
				$monitor['data'].=sprintf(' %02x',$Byte);
			}
		else
			$monitor['data']='0x '.$this->Data;
		$commandes=cmd::byLogicalId($this->AdrGroup);
		if(count($commandes)>0){
			$Message='';
			foreach($commandes as $Commande){
				if($Commande->getEqType_name() != 'eibd')
					continue;
				if($Message != '' && $Commande->getType() == 'action')
					continue;
				if($this->Mode == "Read" && $Commande->getConfiguration('FlagRead'))
					$Message = $Commande->SendReply();
				elseif($this->Mode == "Write" && $Commande->getConfiguration('FlagWrite'))
					$Message = $Commande->UpdateCommande($this->Data);
				elseif($this->Mode == "Reponse" && $Commande->getConfiguration('FlagUpdate'))
					$Message = $Commande->UpdateCommande($this->Data);
				$monitor['valeur'] = $Message;
				$monitor['cmdJeedom'] = $Commande->getHumanName();
				$monitor['DataPointType'] = $Commande->getConfiguration('KnxObjectType');
			}
		}else {
			$dpt=Dpt::getDptFromData($data["Data"]);
			if($dpt!=false){
				$monitor['valeur'] = Dpt::DptSelectDecode($dpt, $this->Data);
				$monitor['DataPointType']= $dpt;
				if(config::byKey('isInclude','eibd'))
					//event::add('eibd::GadInconnue', json_encode($monitor));
					eibd::addCacheNoGad($monitor);
				
			}else
				$monitor['valeur']="Impossible de convertir la valeur";
			$monitor['cmdJeedom']= "La commande n'exites pas";
			log::add('eibd', 'debug', 'Aucune commande avec l\'adresse de groupe  '.$this->AdrGroup.' n\'a pas été trouvée');
		}
		$monitor['datetime'] = date('d-m-Y H:i:s');
		event::add('eibd::monitor', json_encode($monitor));
		unset($this);
		//exit();
	}
	private function formatiaddr ($addr){
		return sprintf ("%d.%d.%d", ($addr >> 12) & 0x0f, ($addr >> 8) & 0x0f, $addr & 0xff);
	}
	private function formatgaddr ($addr)	{
		switch(config::byKey('level', 'eibd')){
			case '3':
				return sprintf ("%d/%d/%d", ($addr >> 11) & 0x1f, ($addr >> 8) & 0x07,$addr & 0xff);
			break;
			case '2':
				return sprintf ("%d/%d", ($addr >> 11) & 0x1f,$addr & 0x7ff);
			break;
			case '1':
				return sprintf ("%d", $addr);
			break;
		}
	}
}
?>