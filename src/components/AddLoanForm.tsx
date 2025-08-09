import { useState } from "react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Plus, DollarSign, User } from "lucide-react";

interface AddLoanFormProps {
  onAddLoan: (name: string, amount: number) => void;
}

const AddLoanForm = ({ onAddLoan }: AddLoanFormProps) => {
  const [name, setName] = useState("");
  const [amount, setAmount] = useState("");

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    
    if (!name.trim() || !amount || isNaN(parseFloat(amount))) {
      return;
    }
    
    onAddLoan(name.trim(), parseFloat(amount));
    setName("");
    setAmount("");
  };

  return (
    <Card className="bg-gradient-card border-border/50 shadow-card">
      <CardHeader>
        <CardTitle className="flex items-center text-foreground">
          <Plus className="w-5 h-5 mr-2 text-primary" />
          Add New Loan
        </CardTitle>
      </CardHeader>
      
      <CardContent>
        <form onSubmit={handleSubmit} className="space-y-4">
          <div className="space-y-2">
            <Label htmlFor="borrower-name" className="flex items-center text-foreground">
              <User className="w-4 h-4 mr-1" />
              Borrower Name
            </Label>
            <Input
              id="borrower-name"
              type="text"
              placeholder="Enter borrower's name"
              value={name}
              onChange={(e) => setName(e.target.value)}
              className="bg-background border-border focus:border-primary"
              required
            />
          </div>
          
          <div className="space-y-2">
            <Label htmlFor="loan-amount" className="flex items-center text-foreground">
              <DollarSign className="w-4 h-4 mr-1" />
              Loan Amount
            </Label>
            <Input
              id="loan-amount"
              type="number"
              placeholder="0.00"
              step="0.01"
              min="0"
              value={amount}
              onChange={(e) => setAmount(e.target.value)}
              className="bg-background border-border focus:border-primary"
              required
            />
          </div>
          
          <Button 
            type="submit" 
            className="w-full bg-gradient-primary hover:opacity-90 text-primary-foreground font-semibold shadow-elegant"
          >
            <Plus className="w-4 h-4 mr-2" />
            Add Loan
          </Button>
        </form>
      </CardContent>
    </Card>
  );
};

export default AddLoanForm;