import {
  IsEmail,
  IsNotEmpty,
  IsString,
  IsBoolean,
  IsOptional,
  IsNumber,
  isNotEmpty,
} from 'class-validator';

export class CreateUserDto {
  @IsString()
  @IsNotEmpty()
  nome: string;

  @IsEmail()
  email: string;

  @IsString()
  @IsNotEmpty()
  senha_hash: string;

  @IsOptional()
  @IsString()
  foto_url?: string;

  @IsBoolean()
  ativo: boolean;

  @IsNumber()
  @IsOptional()
  score?: number;

  @IsString()
  firebaseUid: string;
}
