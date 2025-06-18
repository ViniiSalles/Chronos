import {
  IsString,
  IsNotEmpty,
  IsMongoId,
  IsDateString,
  IsOptional,
  IsArray,
  IsEnum,
} from 'class-validator';
import { Complexidade } from 'src/types/types';

export class CreateTaskDto {
  @IsString()
  @IsNotEmpty()
  titulo: string;

  @IsString()
  @IsOptional()
  descricao?: string;

  @IsString()
  @IsNotEmpty()
  prioridade: string;

  @IsEnum(Complexidade)
  complexidade: Complexidade;

  @IsMongoId()
  @IsNotEmpty()
  projeto: string;

  @IsString()
  @IsNotEmpty()
  status: string;

  @IsDateString()
  @IsOptional()
  dataInicio?: string;

  @IsDateString()
  @IsOptional()
  dataLimite?: string;

  @IsDateString()
  @IsOptional()
  dataConclusao?: string;

  @IsMongoId()
  @IsOptional()
  aprovadaPor?: string;

  @IsArray()
  @IsMongoId({ each: true })
  @IsOptional()
  atribuicoes?: string[];

  @IsOptional()
  @IsArray()
  @IsMongoId({ each: true })
  tarefasAnteriores?: string[];

}
